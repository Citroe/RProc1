`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: John Processor Inc
// Engineer: TSon
// 
// Create Date: 04/03/2026 06:38:07 PM
// Design Name: N-bit Multiplexer
// Module Name: muxN
// Project Name: Rage1
// Target Devices: Basys3
// Tool Versions: Vivado 2024.1
// Description: A n-bit mux to avoid having multiple muxes in this project 
// 
// Dependencies: None
// 
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module muxN #(
    parameter width = 32, //Data width (32 for now but can also be 16 in thumb mode)
    parameter num_inputs = 8, //Total number of sources
    parameter sel_width =3 //log2(num_inputs) 
    )(
        input wire [(width*num_inputs) - 1:0] d_in, //all inputs flatened
        input wire [sel_width-1:0] sel,
        output wire [width-1:0] y
    );
    
    assign y = d_in[sel*width+:width]; //extract the selected bit width chunk from the flattened vector
    
    
endmodule
