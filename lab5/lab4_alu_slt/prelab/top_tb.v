`timescale 1ns / 1ns
// Self-checking testbench. Change N here and it propagates to every module.
module top_tb;

parameter N = 4;

// Inputs
reg [N-1:0] a, b;
reg         c_in, sel, clk;

// Outputs
wire [N-1:0] q;
wire         c_out;

// Unit Under Test
top #(.N(N)) uut (.q(q), .c_out(c_out), .a(a), .b(b), .c_in(c_in), .sel(sel), .clk(clk));

// Verification logic (parameterized)
reg [N:0]   exp_full;   // N+1 bits to capture carry
reg [N-1:0] exp_q;
reg         exp_cout;
integer     errors, checks;

initial begin
	clk = 0; a = 0; b = 0; c_in = 0; sel = 0;
	errors = 0; checks = 0;
end

always #5 clk = ~clk;

// Drive new random inputs on the falling edge
always @(negedge clk) begin
	a    = $random;
	b    = $random;
	c_in = $random;
	sel  = $random;
end

// Compute expected value from the inputs seen at the rising edge,
// then compare the registered output just after the edge.
always @(posedge clk) begin
	exp_full = a + b + c_in;
	exp_cout = exp_full[N];
	exp_q    = sel ? ~a : exp_full[N-1:0];
	#1;
	if (^q === 1'bx) begin
		errors = errors + 1;
		$display("ERROR t=%0t: q is X/Z", $time);
	end else begin
		checks = checks + 1;
		if (q !== exp_q) begin
			errors = errors + 1;
			$display("ERROR t=%0t: sel=%b a=%0d b=%0d cin=%b q=%0d expected=%0d",
			         $time, sel, a, b, c_in, q, exp_q);
		end
		// carry out is combinational; only meaningful for the adder path
		if (!sel && c_out !== exp_cout) begin
			errors = errors + 1;
			$display("ERROR t=%0t: c_out=%b expected=%b", $time, c_out, exp_cout);
		end
	end
end

initial begin
	#2000;
	$display("DONE: %0d checks, %0d errors", checks, errors);
	if (errors == 0) $display("PASS");
	else             $display("FAIL");
	$finish;
end

initial begin
	$dumpfile("top_tb.vcd");
	$dumpvars(0, top_tb);
end

endmodule