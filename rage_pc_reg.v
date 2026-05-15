`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: John Processor Inc
// Engineer: TSon
// 
// Create Date: 04/03/2026 06:16:34 PM
// Design Name: D-flip flop based Program Counter
// Module Name: rage_pc_reg
// Project Name: Rage1
// Target Devices: Basys3
// Tool Versions: Vivado 2024.1
// Description: A simple D flip flop based register to serve as the program counter (for r type instructions))
// 
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

parameter reset_addr = 32'h0000_0000;

module rage_pc_reg(
    input wire clk,
    input wire rst, //synchronous reset (add or posedge rst if you need async rst)
    input wire en,  
    input wire [31:0] d, //next pc value
    output reg [31:0] q  //current pc value
    );
    
    //implicit stall when no en and no rst
    always @(posedge clk) begin
        if (rst) begin
         q <= reset_addr;
        end else if (en) begin
            q <= d;
        end
    end
    
endmodule
