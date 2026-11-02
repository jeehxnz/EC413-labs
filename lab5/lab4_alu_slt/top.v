`timescale 1ns / 1ns
module top #(parameter WIDTH = 32) (R0, c_out, R2, R3, ALUOp, clk);

input [WIDTH-1:0] R2, R3;
input [2:0] ALUOp;
input clk;
output [WIDTH-1:0] R0;
output c_out;

wire [WIDTH-1:0] R1;   // ALU output, register input

ALU #(.WIDTH(WIDTH)) u_alu (.R1(R1), .c_out(c_out), .R2(R2), .R3(R3), .ALUOp(ALUOp));

reg_n #(.N(WIDTH)) u_reg (.q(R0), .d(R1), .clk(clk));

endmodule