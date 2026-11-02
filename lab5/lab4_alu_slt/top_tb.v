`timescale 1ns / 1ns
module top_tb;

parameter WIDTH = 32;

// Corner values built from WIDTH so they work at any width
localparam [WIDTH-1:0] ALL_ONES = {WIDTH{1'b1}};   // -1
localparam [WIDTH-1:0] MAX_POS  = ALL_ONES >> 1;   // largest positive
localparam [WIDTH-1:0] MIN_NEG  = ~MAX_POS;        // most negative

reg [WIDTH-1:0] R2, R3;
reg [2:0]       ALUOp;
reg             clk;

wire [WIDTH-1:0] R0;
wire             c_out;
wire [WIDTH-1:0] exp_R1;   // expected ALU result from the behavioral reference

top #(.WIDTH(WIDTH)) uut (.R0(R0), .c_out(c_out), .R2(R2), .R3(R3),
                          .ALUOp(ALUOp), .clk(clk));

ALU_behavioral #(.WIDTH(WIDTH)) ref_alu (.R2(R2), .R3(R3), .ALUOp(ALUOp), .R1(exp_R1));

// Clock: period 10 ns
initial clk = 0;
always #5 clk = ~clk;

reg [WIDTH-1:0] corner [0:5];   // corner-case operand list
reg [WIDTH-1:0] prev_R0;        // register value before inputs change
reg [WIDTH:0]   full;           // WIDTH+1 bits to capture the carry
reg             have_prev;      // 0 until the register has been loaded once
integer         errors, checks, op, i, j, k;

// Apply one test: change inputs on the falling edge, check R0 holds until the
// next rising edge, check c_out (ADD/SUB), then check R0 after the rising edge.
task run_test(input [2:0] test_op, input [WIDTH-1:0] x, input [WIDTH-1:0] y);
begin
	@(negedge clk);
	prev_R0 = R0;
	R2 = x;  R3 = y;  ALUOp = test_op;
	#1;

	// R0 must not change between clock edges
	if (have_prev && R0 !== prev_R0) begin
		errors = errors + 1;
		$display("ERROR t=%0t: R0 changed between clock edges", $time);
	end

	// expected carry out (only meaningful for ADD and SUB)
	if (test_op == 3'b010) full = {1'b0, R2} + {1'b0, R3};
	if (test_op == 3'b011) full = {1'b0, R2} + {1'b0, ~R3} + 1;
	if ((test_op == 3'b010 || test_op == 3'b011) && c_out !== full[WIDTH]) begin
		errors = errors + 1;
		$display("ERROR t=%0t: op=%b R2=%h R3=%h c_out=%b expected=%b",
		         $time, test_op, R2, R3, c_out, full[WIDTH]);
	end

	// after the rising edge R0 must equal the reference result
	@(posedge clk);
	#1;
	checks = checks + 1;
	if (R0 !== exp_R1) begin
		errors = errors + 1;
		$display("ERROR t=%0t: op=%b R2=%h R3=%h R0=%h expected=%h",
		         $time, test_op, R2, R3, R0, exp_R1);
	end
	have_prev = 1;
end
endtask

initial begin
	errors = 0;  checks = 0;  have_prev = 0;
	corner[0] = 0;        corner[1] = 1;        corner[2] = ALL_ONES;
	corner[3] = MAX_POS;  corner[4] = MIN_NEG;  corner[5] = 2;

	// Corner cases: every pair of corner values for every function
	for (op = 0; op < 6; op = op + 1)
		for (i = 0; i < 6; i = i + 1)
			for (j = 0; j < 6; j = j + 1)
				run_test(op, corner[i], corner[j]);

	// Random values for every function (includes equal and random operands)
	for (op = 0; op < 6; op = op + 1)
		for (k = 0; k < 200; k = k + 1)
			run_test(op, $random, $random);

	// Equal operands for SUB (result 0)
	for (k = 0; k < 10; k = k + 1) begin
		i = $random;
		run_test(3'b011, i, i);
	end

	$display("WIDTH=%0d DONE: %0d checks, %0d errors", WIDTH, checks, errors);
	if (errors == 0) $display("PASS");
	else             $display("FAIL");
	$finish;
end

initial begin
	$dumpfile("top_tb.vcd");
	$dumpvars(0, top_tb);
end

endmodule