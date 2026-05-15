`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: John Processor Inc
// Engineer: TSon
// 
// Create Date: 04/16/2026 05:18:33 AM
// Design Name: The Arithmetic Logic UNit
// Module Name: rage_alu
// Project Name: Rage1
// Target Devices: Basys3
// Tool Versions: Vivado 2024.1
// Description: The ALU to handle arithmetic, shifting and logical operations.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - ALU Blueprint
// Additional Comments:
// 
// References:
// Chapter 9 from Computer Organization and Architecture Designing for Performance - William Stallings
// 14.1.1 from The Art of Electronics - Paul Horowitz, Winfield Hill
// 2.4 from The RISC-V Instruction Set Manual Volume 1
//////////////////////////////////////////////////////////////////////////////////


module rage_alu (
    input  wire [31:0] i_a,         // Operand A
    input  wire [31:0] i_b,         // Operand B
    input  wire [3:0]  i_alu_op,    // Control signal from Control Unit
    output reg  [31:0] o_result,
    output wire        o_zero       // Helpful for Branch comparisons
);

    always @(*) begin
        case (i_alu_op)
            4'b0000: o_result = i_a + i_b;                      // ADD
            4'b1000: o_result = i_a - i_b;                      // SUB
            4'b0001: o_result = i_a << i_b[4:0];                // SLL (Shift Left) -> Probably a barrel shifter -> Remove if not enough LUTs 
            4'b0010: o_result = ($signed(i_a) < $signed(i_b));  // SLT (Set Less Than)
            4'b0100: o_result = i_a ^ i_b;                      // XOR
            4'b0101: o_result = i_a >> i_b[4:0];                // SRL (Shift Right)
            4'b1101: o_result = $signed(i_a) >>> i_b[4:0];      // SRA (Arithmetic Shift)
            4'b0110: o_result = i_a | i_b;                      // OR
            4'b0111: o_result = i_a & i_b;                      // AND
            default: o_result = 32'h0;
        endcase
    end

    assign o_zero = (o_result == 32'h0);

endmodule
