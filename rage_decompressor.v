`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/01/2026 02:16:41 PM
// Design Name: 
// Module Name: rage_decompressor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module rage_decompressor (
    input  wire [31:0] i_raw_instr,    // Raw 32-bit word fetched from IMEM
    output reg  [31:0] o_norm_instr,   // Normalized 32-bit instruction for ID stage
    output reg  [1:0]  o_pc_inc        // PC increment value: 2 for 16-bit, 4 for 32-bit
);

    // Extract fields from the 16-bit compressed instruction space
    wire [15:0] c_inst = i_raw_instr[15:0];
    wire [2:0]  c_funct3 = c_inst[15:13];
    wire [1:0]  c_op     = c_inst[1:0];
    
    // Common compressed register mappings (Registers x8 to x15 are popular in RVC)
    wire [4:0]  c_rs1_prime = {2'b01, c_inst[9:7]};  // Maps 3 bits to x8-x15
    wire [4:0]  c_rd_prime  = {2'b01, c_inst[4:2]};  // Maps 3 bits to x8-x15
    wire [4:0]  c_rd_raw    = c_inst[11:7];          // Standard 5-bit register field

    always @(*) begin
        // Default assignments to prevent latches
        o_norm_instr = i_raw_instr;
        o_pc_inc     = 2'd4;

        if (c_op == 2'b11) begin
            // --- Standard 32-bit Instruction Pass-Through ---
            o_norm_instr = i_raw_instr;
            o_pc_inc     = 2'd4;
        end else begin
            // --- RV32C 16-bit Decompression ---
            o_pc_inc = 2'd2; // Default increment for compressed instructions
            
            case (c_op)
                2'b01: begin // Quadrant 1
                    case (c_funct3)
                        3'b000: begin // c.addi -> addi rd, rd, nzimm
                            // Expands sign-extended 6-bit immediate
                            o_norm_instr = { {26{c_inst[12]}}, c_inst[6:2], c_rd_raw, 3'b000, c_rd_raw, 7'b0010011 };
                        end
                        // Add other Quadrant 1 instructions here (e.g., c.jal, c.li)
                        default: o_norm_instr = 32'h00000013; // Default to NOP (addi x0, x0, 0)
                    endcase
                end

                2'b00: begin // Quadrant 0
                    case (c_funct3)
                        3'b010: begin // c.lw -> lw rd', offset(rs1')
                            // Explicit 12-bit immediate concatenation:
                            // inst[5] -> imm[5], inst[12:10] -> imm[4:2], inst[6] -> imm[3], padded with zeros
                            o_norm_instr = { 
                                5'b0000000, c_inst[5], c_inst[12:10], c_inst[6], 2'b00, // [31:20] 12-bit Immediate (forced 7-bit leading padding)
                                c_rs1_prime,                                            // [19:15] Source Register (x10)
                                3'b010,                                                 // [14:12] Funct3 (LW)
                                c_rd_prime,                                             // [11:7]  Destination Register (x11)
                                7'b0000011                                              // [6:0]   Opcode (Load)
                            };
                            o_pc_inc = 2'd2; // Ensure your branch updates width tracking explicitly
                        end
                        default: o_norm_instr = 32'h00000013;
                    endcase
                end

                2'b10: begin // Quadrant 2
                    // Handles stack-pointer relative instructions (e.g., c.lwsp, c.swsp)
                    o_norm_instr = 32'h00000013;
                end

                default: o_norm_instr = 32'h00000013; // Safe NOP fallback
            endcase
        end
    end

endmodule
