`timescale 1ns / 1ns

module tb_lui;
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
		$dumpfile("lui.vcd");
		$dumpvars(0, tb_lui);

		rst = 1; clk = 0; initialize = 1;
		instruction_initialize_data = 0;
		instruction_initialize_address = 0;
		#100;

		// registers start as R[i] = 10*i, so R1..R5 hold old values 10..50 before being overwritten
		//          opcode rs    rt    immediate
		load(0,  32'b001111_00000_00001_1010010111000011);   //  0: LUI R1,0xA5C3 -> A5C30000 (mixed 0s and 1s)
		load(4,  32'b001111_00000_00010_0101101001011010);   //  4: LUI R2,0x5A5A -> 5A5A0000 (mixed, opposite pattern)
		load(8,  32'b001111_00000_00011_1111111111111111);   //  8: LUI R3,0xFFFF -> FFFF0000 (all ones)
		load(12, 32'b001111_00000_00100_0000000000000000);   // 12: LUI R4,0x0000 -> 00000000 (all zeros, old R4=40)
		load(16, 32'b001111_00000_00101_1000000000000001);   // 16: LUI R5,0x8001 -> 80010000 (top bit set)
		load(20, 32'b000010_00000000000000000000000101);     // 20: J 20          (park PC)

		initialize = 0;
		rst = 0;
		#100;

		check(1, 32'hA5C30000, "LUI A5C3 mixed bits  ");
		check(2, 32'h5A5A0000, "LUI 5A5A mixed bits  ");
		check(3, 32'hFFFF0000, "LUI FFFF all ones    ");
		check(4, 32'h00000000, "LUI 0000 all zeros   ");
		check(5, 32'h80010000, "LUI 8001 top bit set ");

		// explicitly verify the low 16 bits are zero in every result
		if (uut.Register_File.register_file[1][15:0] !== 16'h0000 ||
		    uut.Register_File.register_file[2][15:0] !== 16'h0000 ||
		    uut.Register_File.register_file[3][15:0] !== 16'h0000 ||
		    uut.Register_File.register_file[5][15:0] !== 16'h0000) begin
			$display("FAIL low 16 bits are not all zero");
			errors = errors + 1;
		end else
			$display("PASS low 16 bits are zero in all results");

		if (errors == 0) $display("ALL LUI TESTS PASSED");
		else             $display("%0d LUI TEST(S) FAILED", errors);
		$finish;
	end

	always #5 clk = ~clk;
endmodule
