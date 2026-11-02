`timescale 1ns / 1ns

module reg_n #(parameter N = 4) (q, d, clk);

input  [N-1:0] d;
input clk;
output [N-1:0] q;
genvar i;
generate
	for (i = 0; i < N; i = i + 1) begin : gen_reg
		dff dff_i (.q(q[i]), .d(d[i]), .clk(clk));
	end
endgenerate

endmodule