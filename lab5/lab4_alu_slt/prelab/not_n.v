`timescale 1ns / 1ns
// N-bit bitwise NOT built with generate
module not_n #(parameter N = 4) (y, a);

input  [N-1:0] a;
output [N-1:0] y;

genvar i;
generate
	for (i = 0; i < N; i = i + 1) begin : gen_not
		not not_i (y[i], a[i]);
	end
endgenerate

endmodule