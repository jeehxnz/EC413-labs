`timescale 1ns / 1ns
// N-bit ripple-carry adder built from N instances of FA_str using generate
module adder_n #(parameter N = 4) (c_out, sum, a, b, c_in);

input  [N-1:0] a, b;
input         c_in;
output [N-1:0] sum;
output         c_out;

wire [N:0] c;          // carry chain: c[0] = c_in, c[N] = c_out
assign c[0] = c_in;

genvar i;
generate
	for (i = 0; i < N; i = i + 1) begin : gen_fa
		FA_str fa_i (.c_out(c[i+1]), .sum(sum[i]), .a(a[i]), .b(b[i]), .c_in(c[i]));
	end
endgenerate

assign c_out = c[N];

endmodule