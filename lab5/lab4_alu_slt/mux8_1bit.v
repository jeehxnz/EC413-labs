`timescale 1ns / 1ns
module mux8_1bit (y, d, sel);

input  [7:0] d;
input  [2:0] sel;
output       y;

assign y = d[sel];

endmodule