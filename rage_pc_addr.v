`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Johhn Processor Inc
// Engineer: TSon
// 
// Create Date: 04/04/2026 06:16:06 PM
// Design Name: Discrete PC Incrementer
// Module Name: rage_pc_addr
// Project Name: Rage1
// Target Devices: Basys3
// Tool Versions: Vivado 2024.1
// Description: A discrete PC incrementer to support compressed mode and branch instructions along with easier diagnosing and debugging
// 
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rage_pc_addr(
    input wire [31:0] a, //current PC
    input wire [31:0] b, //increment, can be  2(compressed), 4(32-bit) or required branch offset
    output wire [31:0] y //incremented PC (next PC)
    );
    
    assign y = a + b;
    
endmodule
