`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: John Processor Inc
// Engineer: TSon
// 
// Create Date: 04/07/2026 03:31:16 AM
// Design Name: Immeditae extreactor
// Module Name: rage_imm_gen
// Project Name: Rage1
// Target Devices: Basys3
// Tool Versions: Vivado 2024.1 
// Description: Extract signed immediate value from the ocpode
// 
// Dependencies: None (For Rev 0.02)
//               MuxN (For Rev 0.03)
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Immediate Generator using always and support for only I,S,J,U and B
// Revision 0.03 -  Using the n-bit mux instead and space for future Atomic ops
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rage_imm_gen(
    input wire [31:0] i_instr, //input instruction
    output reg [31:0] o_imm, //output immediate
    input wire [2:0] i_imm_sel //input control signal (from decoder)
    );
    
    //Rev 0.02
    /*
    wire [6:0] opcode = i_instr[6:0]; //opcode instruction 
   
    always @(*) begin
        case (opcode)
            7'b0010011, 7'b0000011: // I-Type (Op-Imm, Load)
                o_imm = {{20{i_instr[31]}}, i_instr[31:20]};
            7'b0100011: // S-Type (Store)
                o_imm = {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:7]};
            7'b1100011: // B-Type (Branch)
                o_imm = {{19{i_instr[31]}}, i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};
            7'b1101111: // J-Type (JAL)
                o_imm = {{11{i_instr[31]}}, i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0};
            7'b0110111, 7'b0010111: // U-Type (LUI, AUIPC)
                o_imm = {i_instr[31:12], 12'b0};
            default: 
                o_imm = 32'h0;
        endcase
    end
    */
    
    //Rev 0.03
    wire [31:0] imm_i = {{20{i_instr[31]}}, i_instr[31:20]};
    wire [31:0] imm_s = {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:8], i_instr[7]};
    wire [31:0] imm_b = {{19{i_instr[31]}}, i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0};
    wire [31:0] imm_u = {i_instr[31:12], 12'b0};
    wire [31:0] imm_j = {{11{i_instr[31]}}, i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0};
    
    muxN #(.width(32)) imm_selector (
        .i_sel(i_imm_sel),
        .i_in0(imm_i),
        .i_in1(imm_s),
        .i_in2(imm_b),
        .i_in3(imm_u),
        .i_in4(imm_j),
        .i_in5(32'h0), // Placeholder for Atomic or future expansion
        .i_in6(32'h0),
        .i_in7(32'h0),
        .o_data(o_imm)
    );
endmodule
    
            