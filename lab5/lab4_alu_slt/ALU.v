`timescale 1ns / 1ns
// Parameterized N-bit ALU built from 1-bit ALU_slice modules
// Parameter: WIDTH - word size (default 32)
// Inputs   : R2, R3 - operands, ALUOp[2:0] - function select
// Outputs  : R1 - result, c_out - final carry out
//   ALUOp: 000 MOV, 001 NOT, 010 ADD, 011 SUB, 100 OR, 101 AND, 110 SLT (signed)
module ALU #(parameter WIDTH = 32) (R1, c_out, R2, R3, ALUOp);

input  [WIDTH-1:0] R2, R3;
input  [2:0]       ALUOp;
output [WIDTH-1:0] R1;
output             c_out;

wire [WIDTH:0]   carry;     // carry[0] = carry in, carry[WIDTH] = carry out
wire [WIDTH-1:0] sum_bits;  // raw adder sum of every slice (R2 - R3 for SLT)

// Subtract decode: is_sub = 1 for SUB (011) and for SLT (110)
wire not_op2, not_op0;
wire sub_op, slt_op, is_sub;
not n_op2   (not_op2, ALUOp[2]);
not n_op0   (not_op0, ALUOp[0]);
and a_subop (sub_op, not_op2, ALUOp[1], ALUOp[0]);   // 011
and a_sltop (slt_op, ALUOp[2], ALUOp[1], not_op0);   // 110
or  o_issub (is_sub, sub_op, slt_op);

// SLT (signed): R2 < R3
//   same signs: no overflow possible, answer = sign bit of the difference
//   different signs: answer = sign bit of R2 (R2 negative means R2 is smaller)
wire r2_msb, r3_msb, diff_msb;
wire not_r2_msb, not_r3_msb;
wire both_neg, both_pos, same_sign;
wire slt_same, slt_mixed, slt_bit;

assign r2_msb   = R2[WIDTH-1];
assign r3_msb   = R3[WIDTH-1];
assign diff_msb = sum_bits[WIDTH-1];

not n_r2m (not_r2_msb, r2_msb);                  // ~R2 sign: 1 when R2 is non-negative
not n_r3m (not_r3_msb, r3_msb);                  // ~R3 sign: 1 when R3 is non-negative
and a_bn  (both_neg, r2_msb, r3_msb);            // 1 when R2 and R3 are both negative
and a_bp  (both_pos, not_r2_msb, not_r3_msb);    // 1 when R2 and R3 are both non-negative
or  o_ss  (same_sign, both_neg, both_pos);       // 1 when the signs match (an XNOR from gates)
and a_sd  (slt_same, same_sign, diff_msb);       // same sign: no overflow, so use the sign of R2 - R3
and a_sm  (slt_mixed, r2_msb, not_r3_msb);       // R2 negative, R3 non-negative: R2 is smaller, so 1
or  o_slt (slt_bit, slt_same, slt_mixed);        // final SLT bit: 1 if either case says R2 < R3

// Carry into bit 0: SUB and SLT add 1 (two's complement)
assign carry[0] = is_sub;

genvar i;
generate
	for (i = 0; i < WIDTH; i = i + 1) begin : gen_slice
		// only bit 0 receives the SLT bit; all other bits of an SLT result are 0
		ALU_slice slice (.result(R1[i]), .cout(carry[i+1]), .sum_out(sum_bits[i]),
		                 .a(R2[i]), .b(R3[i]), .cin(carry[i]),
		                 .binvert(is_sub), .slt_in((i == 0) ? slt_bit : 1'b0),
		                 .ALUOp(ALUOp));
	end
endgenerate

assign c_out = carry[WIDTH];

endmodule