`timescale 1ns / 1ns
// Top level: MUX selects between adder result (sel=0) and bitwise NOT of a (sel=1) & the MUX output feeds the N-bit register.
module top #(parameter N = 4) (q, c_out, a, b, c_in, sel, clk);

input  [N-1:0] a, b;
input          c_in, sel, clk;
output [N-1:0] q;
output         c_out;

wire [N-1:0] sum, not_out, mux_out;

adder_n #(.N(N)) u_add (.c_out(c_out), .sum(sum), .a(a), .b(b), .c_in(c_in));
not_n   #(.N(N)) u_not (.y(not_out), .a(a));

assign mux_out = sel ? not_out : sum;

reg_n   #(.N(N)) u_reg (.q(q), .d(mux_out), .clk(clk));

endmodule