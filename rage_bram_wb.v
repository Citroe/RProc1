`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: John Processor Inc
// Engineer: TSon
// 
// Create Date: 04/07/2026 01:53:14 AM
// Design Name: Block RAM with wishbone interface
// Module Name: rage_bram_wb
// Project Name: Rage1
// Target Devices: Basys3
// Tool Versions: Vivado 2024.1, Google Gemini
// Description: Generic block RAM module with a wisbone interface
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//we follow the wishbone naming conventions, _i for input and _o for output, input is from external to core and output is core to external

module rage_bram_wb #(
    parameter MEM_SIZE = 1024 // Number of 32-bit words
)(
    input  wire        i_clk, //general purpose so no wb (wb is for wishbone ports and stuff)
    input  wire        i_rst,
    // Wishbone Slave Interface
    input  wire [31:0] i_wb_adr, //address bus
    input  wire [31:0] i_wb_dat, //data bus
    input  wire [3:0]  i_wb_sel, //byte select (this thing strobes?)
    input  wire        i_wb_we,  //write enable
    input  wire        i_wb_stb, //strobe
    input  wire        i_wb_cyc, //cycle valid
    output reg         o_wb_ack, //acknowledge output 
    output wire [31:0] o_wb_dat //data bus output
);
    // The actual memory array - Vivado will infer BRAM from this
    reg [31:0] ram [0:MEM_SIZE-1];

    // Read Logic
    assign o_wb_dat = ram[i_wb_adr[31:2]]; // Word-aligned access

    // Write & Ack Logic
    always @(posedge i_clk) begin //All WISHBONE interfaces MUST initialize themselves at the rising [CLK_I] edge (rule3.00)
        if (i_rst) begin
            o_wb_ack <= 1'b0; //Rule 3.00 compliance
        end else begin
            // Wishbone Handshake(only acknowledge IF a cycle is actually active)
            o_wb_ack <= i_wb_stb && i_wb_cyc && !o_wb_ack;
            
            if (i_wb_stb && i_wb_cyc && i_wb_we) begin
                // Handle byte-level writes using SEL
                if (i_wb_sel[0]) ram[i_wb_adr[31:2]][7:0]   <= i_wb_dat[7:0];
                if (i_wb_sel[1]) ram[i_wb_adr[31:2]][15:8]  <= i_wb_dat[15:8];
                if (i_wb_sel[2]) ram[i_wb_adr[31:2]][23:16] <= i_wb_dat[23:16];
                if (i_wb_sel[3]) ram[i_wb_adr[31:2]][31:24] <= i_wb_dat[31:24];
            end
        end
    end
endmodule
