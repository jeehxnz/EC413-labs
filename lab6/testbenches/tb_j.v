`timescale 1ns / 1ns

module tb_j;
	reg rst, clk, initialize;
	reg [31:0] instruction_initialize_data;
	reg [31:0] instruction_initialize_address;

	cpu uut (.rst(rst), .clk(clk), .initialize(initialize),
	         .instruction_initialize_data(instruction_initialize_data),
	         .instruction_initialize_address(instruction_initialize_address));

	integer errors = 0;

	task load(input [31:0] addr, input [31:0] data);
	begin
		instruction_initialize_address = addr;
		instruction_initialize_data    = data;
		#10;
	end
	endtask

	task check(input integer r, input [31:0] expected, input [255:0] name);
	begin
		if (uut.Register_File.register_file[r] !== expected) begin
			$display("FAIL %0s: R%0d = %h, expected %h", name, r, uut.Register_File.register_file[r], expected);
			errors = errors + 1;
		end else
			$display("PASS %0s: R%0d = %h", name, r, uut.Register_File.register_file[r]);
	end
	endtask

	initial begin
		$dumpfile("j.vcd");
		$dumpvars(0, tb_j);

		rst = 1; clk = 0; initialize = 1;
		instruction_initialize_data = 0;
		instruction_initialize_address = 0;
		#100;

		// registers start as R[i] = 10*i  (R2 = 20, R4 = 40)
		//          opcode  26-bit target (word address)
		load(0,  32'b001000_00000_00001_0000000000000001);   //  0: ADDI R1,R0,1   -> R1 = 1
		load(4,  32'b000010_00000000000000000000000100);     //  4: J 16           (word addr 4)
		load(8,  32'b001000_00000_00010_0000000001100011);   //  8: ADDI R2,R0,99  (skipped)
		load(12, 32'b001000_00000_00100_0000000001001101);   // 12: ADDI R4,R0,77  (skipped)
		load(16, 32'b001000_00000_00011_0000000000000101);   // 16: ADDI R3,R0,5   -> R3 = 5
		load(20, 32'b000010_00000000000000000000000101);     // 20: J 20           (park PC)

		initialize = 0;
		rst = 0;
		#100;

		check(1, 32'd1,  "before jump executed ");
		check(2, 32'd20, "skipped instr 1 (R2) ");
		check(4, 32'd40, "skipped instr 2 (R4) ");
		check(3, 32'd5,  "jump target executed ");
		if (uut.PC_out !== 32'd20) begin
			$display("FAIL PC parked at %0d, expected 20", uut.PC_out);
			errors = errors + 1;
		end else
			$display("PASS PC parked at 20 (J to itself)");

		if (errors == 0) $display("ALL J TESTS PASSED");
		else             $display("%0d J TEST(S) FAILED", errors);
		$finish;
	end

	always #5 clk = ~clk;
endmodule
