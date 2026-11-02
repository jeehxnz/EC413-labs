`timescale 1ns / 1ns
module ALU_slice_tb;

reg       a, b, cin, binvert;
reg [2:0] ALUOp;
wire      result, cout;

ALU_slice uut (.result(result), .cout(cout), .a(a), .b(b),
               .cin(cin), .binvert(binvert), .ALUOp(ALUOp));

reg [1:0] exp_add;      // {carry, sum} of a + b_adder + cin
reg       exp_result;
integer   errors, op, combo;

initial begin
	errors = 0;
	for (op = 0; op < 6; op = op + 1)
		for (combo = 0; combo < 8; combo = combo + 1) begin
			ALUOp = op;
			{a, b, cin} = combo;
			binvert = (op == 3);               // only SUB inverts b
			#10;

			exp_add = a + (b ^ binvert) + cin;
			case (op)
				0: exp_result = a;             // MOV
				1: exp_result = ~a;            // NOT
				2, 3: exp_result = exp_add[0]; // ADD, SUB
				4: exp_result = a | b;         // OR
				5: exp_result = a & b;         // AND
			endcase

			if (result !== exp_result ||
			    ((op == 2 || op == 3) && cout !== exp_add[1])) begin
				errors = errors + 1;
				$display("ERROR op=%0d a=%b b=%b cin=%b: result=%b cout=%b",
				         op, a, b, cin, result, cout);
			end
		end

	if (errors == 0) $display("PASS");
	else             $display("FAIL: %0d errors", errors);
	$finish;
end

initial begin
	$dumpfile("ALU_slice_tb.vcd");
	$dumpvars(0, ALU_slice_tb);
end

endmodule