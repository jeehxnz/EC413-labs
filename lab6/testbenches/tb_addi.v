`timescale 1ns / 1ns

module tb_addi;
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
		$dumpfile("addi.vcd");
		$dumpvars(0, tb_addi);

		rst = 1; clk = 0; initialize = 1;
		instruction_initialize_data = 0;
		instruction_initialize_address = 0;
		#100;

		// register file starts as R[i] = 10*i  (R0=0, R2=20, R3=30, ...)
		//          opcode rs    rt    immediate
		load(0,  32'b001000_00000_00001_0000000000000101);   // ADDI R1, R0, 5     -> 5
		load(4,  32'b001000_00010_00010_1111111111111101);   // ADDI R2, R2, -3    -> 20-3 = 17
		load(8,  32'b001000_00011_00011_0000000000000000);   // ADDI R3, R3, 0     -> 30 (unchanged)
		load(12, 32'b001000_00000_00100_1111111111111001);   // ADDI R4, R0, -7    -> FFFFFFF9
		load(16, 32'b001000_00001_00101_0000000000001010);   // ADDI R5, R1, 10    -> 5+10 = 15 (uses R1 result)
		load(20, 32'b000100_00000_00000_11111_11111_11_1111);// BEQ R0,R0,-1 (park PC)

		initialize = 0;
		rst = 0;
		#100;

		check(1, 32'd5,          "positive immediate  ");
		check(2, 32'd17,         "negative immediate  ");
		check(3, 32'd30,         "add zero            ");
		check(4, 32'hFFFFFFF9,   "negative from R0    ");
		check(5, 32'd15,         "uses prior ADDI res ");

		if (errors == 0) $display("ALL ADDI TESTS PASSED");
		else             $display("%0d ADDI TEST(S) FAILED", errors);
		$finish;
	end

	always #5 clk = ~clk;
endmodule
