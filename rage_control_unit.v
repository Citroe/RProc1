`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: John Processor Inc
// Engineer: TSon
// 
// Create Date: 04/13/2026 08:19:14 AM
// Design Name: Rage's Control Unit
// Module Name: rage_control_unit
// Project Name: Rage1
// Target Devices: Basys3
// Tool Versions: Vivado 2024.1
// Description: Control unit for the processor 
// 
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//The control unit is that portion of the processor that actually causes things to
//happen.
//From Computer Organization and Architecture Designing for Performance by William Stallings 

module rage_control_unit(
    //inputs
    input wire  [6:0] i_opcode,
    input wire [2:0] i_funct3,
    input wire [6:0] i_funct7,
    
    //outputs
    output reg o_reg_write
    );
endmodule
