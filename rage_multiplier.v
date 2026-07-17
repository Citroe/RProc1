`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: John Processor Inc
// Engineer: TSon
// 
// Create Date: 05/29/2026 01:05:54 PM
// Design Name: Multiplier
// Module Name: rage_multiplier
// Project Name: Rage1
// Target Devices: 
// Tool Versions: Vivado 2024.1
// Description: Multiplier unit
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Changed the state-machine to an AI generated one because my one was not working as intended
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rage_multiplier(
    input wire i_clk, 
    input wire i_rst,
    input wire i_start,
    input wire [31:0] i_multiplicand,
    input wire [31:0] i_multiplier,
    output reg [63:0] o_result,
    output reg o_ready
    );
    
    reg [31:0] a; //Internal Registers, multiplicand
    reg [31:0] q; //Multiplier
    reg [32:0] p; //Partial product 
    reg [5:0] count; //Counter
    
    // State Machine Definitions
    localparam STATE_IDLE = 1'b0;
    localparam STATE_MULT = 1'b1;
    reg state;
    
    wire [32:0] p_next = p + {1'b0, a};
    
    always @(posedge i_clk) begin
        if (i_rst) begin
            state    <= STATE_IDLE;
            o_ready  <= 1'b0;
            o_result <= 64'h0;
            count    <= 6'd0;
            a        <= 32'h0;
            q        <= 32'h0;
            p        <= 33'h0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    o_ready <= 1'b0;
                    if (i_start) begin
                        a     <= i_multiplicand;
                        q     <= i_multiplier;
                        p     <= 33'h0; 
                        count <= 6'd0;
                        state <= STATE_MULT;
                    end
                end

                STATE_MULT: begin
                    count <= count + 1'b1;
                    
                    // 1. ALWAYS perform the shift-and-add for the current bit
                    if (q[0]) begin
                        q <= {p_next[0], q[31:1]};
                        p <= {1'b0, p_next[32:1]};
                    end else begin
                        q <= {p[0], q[31:1]};
                        p <= {1'b0, p[32:1]};
                    end

                    // 2. Check if this WAS our 32nd processing cycle
                    if (count == 6'd31) begin
                        state    <= STATE_IDLE;
                        o_ready  <= 1'b1;
                        // Combine the data that WILL be stable on the next edge
                        o_result <= (q[0]) ? {p_next[32:1], p_next[0], q[31:1]} : {p[32:1], p[0], q[31:1]};
                    end
                end
                
                default: state <= STATE_IDLE;
            endcase
        end
    end
endmodule
