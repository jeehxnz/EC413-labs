`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:16:02 09/28/2013 
// Design Name: 
// Module Name:    dff 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module dff(q, d, clk);

//parameter D = 0;		

input		d, clk; //declare inputs d and clk, 1 bit each
output reg	q;          //declare output q, 1 bit

always @(posedge clk)
q<=d;

endmodule
