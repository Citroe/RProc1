`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: John Processor Inc.
// Engineer: TSon
// 
// Create Date: 06/03/2026 04:00:36 PM
// Design Name: Atom
// Module Name: rage_atomic_unit
// Project Name: Rage
// Target Devices: Basys3
// Tool Versions: Vivado 2024.1
// Description: Unit to processor atomic insturctions
// 
// Dependencies: 
// zalsrc -> Load-reserved/store-conditional
// zaamo -> mMmory
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// Mainly designed with reference to the riscv page and Deepwiki
// livelock not good 
// atomicity scary
//////////////////////////////////////////////////////////////////////////////////


module rage_atomic_unit(
    
    input wire i_clk,
    input wire i_rst,
    
    input wire i_start,
    input wire [3:0] i_amo_op, //3'b001 for amoswap, 3'b01 for LR and 3'b11 for SC; only amoswap for zaamo rn may add the other instructions later
    input wire [31:0] i_addr,
    input wire [31:0] i_rs2_data,
    output reg [31:0] o_core_data,
    output reg o_stall_core, //Pipleine stall by asserting high
    output reg o_align_fault, //Address alignment issue debugging
    
    //Wishbone interface
    output reg o_wb_cyc, //Main bus cycle line 
    output reg o_wb_stb,         
    output reg o_wb_we,          
    output reg [31:0] o_wb_adr, //Master target address 
    output reg [31:0] o_wb_dat, //Master data out 
    input  wire [31:0] i_wb_dat, //Master data in (from memory) 
    input  wire i_wb_ack, //Acknowledge from slave memory 
    
    //Snooping ports (wishbone write lane trace)
    input wire i_snoop_we,
    input wire [31:0] i_snoop_adr
    );
    
    // Core Reservation Registers [cite: 2237]
    reg [31:0] reservation_addr; 
    reg        reservation_valid; 

    // FSM State Encodings
    localparam STATE_IDLE       = 3'b000;
    localparam STATE_READ_REQ   = 3'b001;
    localparam STATE_READ_WAIT  = 3'b010;
    localparam STATE_WRITE_REQ  = 3'b011;
    localparam STATE_WRITE_WAIT = 3'b100;
    reg [2:0] current_state;

    // SC Validation Condition [cite: 2260]
    wire sc_success = reservation_valid && (i_addr == reservation_addr);
    wire is_misaligned = (i_addr[1:0] != 2'b00); // Check 4-byte natural alignment 

    // -------------------------------------------------------------------------
    // Synchronous FSM & Reservation Tracking Logic
    // -------------------------------------------------------------------------
    always @(posedge i_clk) begin
        if (i_rst) begin
            current_state     <= STATE_IDLE;
            reservation_addr  <= 32'h0;
            reservation_valid <= 1'b0; 
            o_stall_core      <= 1'b0;
            o_align_fault     <= 1'b0;
            o_wb_cyc          <= 1'b0;
            o_wb_stb          <= 1'b0;
            o_wb_we           <= 1'b0;
            o_wb_adr          <= 32'h0;
            o_wb_dat          <= 32'h0;
            o_core_data       <= 32'h0;
        end else begin
            // --- CRITICAL EDGE CASE B: Third-Party Snooping Invalidation ---
            // If another master executes a store to our reserved address, it shatters.
            if (i_snoop_we && reservation_valid && (i_snoop_adr == reservation_addr)) begin
                reservation_valid <= 1'b0; // Silently invalidate 
            end

            case (current_state)
                STATE_IDLE: begin
                    o_wb_cyc      <= 1'b0;
                    o_wb_stb      <= 1'b0;
                    o_wb_we       <= 1'b0;
                    o_align_fault <= 1'b0;

                    if (i_start) begin
                        if (is_misaligned) begin
                            // --- EDGE CASE C: Alignment Fault ---
                            o_align_fault <= 1'b1; // Trigger exception flag 
                            o_stall_core  <= 1'b0;  // Drop stall immediately 
                        end else begin
                            o_stall_core  <= 1'b1;  // Pull the pipeline brake 
                            
                            if (i_amo_op == 3'b010) begin
                                // LR.W instruction: Launch a standard read cycle 
                                current_state <= STATE_READ_REQ;
                            end else if (i_amo_op == 3'b011) begin
                                // SC.W instruction: Validate reservation before launching write 
                                if (sc_success) begin
                                    current_state <= STATE_WRITE_REQ;
                                end else begin
                                    // Bypasses memory write completely, forces 32'd1 (Failure)
                                    o_core_data       <= 32'd1; 
                                    reservation_valid <= 1'b0; // Clear on SC failure 
                                    o_stall_core      <= 1'b0;  // Complete transaction instantly
                                    current_state     <= STATE_IDLE;
                                end
                            end else if (i_amo_op == 3'b001) begin
                                // AMOSWAP instruction: Begins multi-cycle Read-Modify-Write 
                                current_state <= STATE_READ_REQ;
                            end
                        end
                    end
                end

                // ---------------------------------------------------------------------
                // READ PHASE (LR.W and AMOSWAP)
                // ---------------------------------------------------------------------
                STATE_READ_REQ: begin
                    o_wb_cyc <= 1'b1; // Drive Wishbone lines high 
                    o_wb_stb <= 1'b1;
                    o_wb_we  <= 1'b0; // It's a read operation
                    o_wb_adr <= i_addr;
                    current_state <= STATE_READ_WAIT;
                end

                STATE_READ_WAIT: begin
                    if (i_wb_ack) begin 
                        o_wb_stb    <= 1'b0; // De-assert strobe 
                        o_core_data <= i_wb_dat; // Trap read data for core WB register file [cite: 1492]
                        
                        if (i_amo_op == 3'b010) begin
                            // LR.W finishes: Register the reservation and return to idle 
                            reservation_addr  <= o_wb_adr; 
                            reservation_valid <= 1'b1;     // Refresh/set validation bit 
                            o_wb_cyc          <= 1'b0;     // Release bus cycle
                            o_stall_core      <= 1'b0;     // Release pipeline stall
                            current_state     <= STATE_IDLE;
                        end else begin
                            // AMOSWAP finishes read: transition to lock-write phase 
                            // CRITICAL: We keep o_wb_cyc HIGH to maintain exclusive bus lock
                            current_state <= STATE_WRITE_REQ;
                        end
                    end
                end

                // ---------------------------------------------------------------------
                // WRITE PHASE (SC.W and AMOSWAP)
                // ---------------------------------------------------------------------
                STATE_WRITE_REQ: begin
                    o_wb_cyc <= 1'b1; // Continuous loop protection
                    o_wb_stb <= 1'b1;
                    o_wb_we  <= 1'b1; // It's a store operation [cite: 1693]
                    o_wb_adr <= i_addr;
                    o_wb_dat <= i_rs2_data; // Supply core operand value to bus lines
                    current_state <= STATE_WRITE_WAIT;
                end

                STATE_WRITE_WAIT: begin
                    if (i_wb_ack) begin 
                        o_wb_cyc <= 1'b0; // --- RELEASE Phase: De-assert CYC to unlock bus ---
                        o_wb_stb <= 1'b0;
                        o_wb_we  <= 1'b0;
                        
                        if (i_amo_op == 3'b011) begin
                            // SC.W completed successfully! Return 32'd0 
                            o_core_data       <= 32'd0;
                            reservation_valid <= 1'b0; // Clear reservation after use
                        end
                        
                        o_stall_core  <= 1'b0; // Drop core stall 
                        current_state <= STATE_IDLE;
                    end
                end

                default: current_state <= STATE_IDLE;
            endcase
        end
    end
endmodule
    
