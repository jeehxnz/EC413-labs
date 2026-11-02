`timescale 1ns / 1ns

module tb_slt;
	reg rst, clk, initialize;
	reg [31:0] instruction_initialize_data;
	reg [31:0] instruction_initialize_address;

	cpu uut (.rst(rst), .clk(clk), .initialize(initialize),
	         .instruction_initialize_data(instruction_initialize_data),
	         .instruction_initialize_address(instruction_initialize_address));

	integer errors = 0;

	// load one instruction word into instruction memory
	task load(input [31:0] addr, input [31:0] data);
	begin
		instruction_initialize_address = addr;
		instruction_initialize_data    = data;
		#10;
	end
	endtask

	// check a register against its expected value
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
		$dumpfile("slt.vcd");
		$dumpvars(0, tb_slt);

		rst = 1; clk = 0; initialize = 1;
		instruction_initialize_data = 0;
		instruction_initialize_address = 0;
		#100;

		// operand setup (register file starts as R[i] = 10*i)
		uut.Register_File.register_file[1] = 32'd5;          // equal pair
		uut.Register_File.register_file[2] = 32'd5;
		uut.Register_File.register_file[3] = 32'd5;          // positive
		uut.Register_File.register_file[4] = -32'sd3;        // negative
		uut.Register_File.register_file[5] = 32'h7FFFFFFF;   // overflow case A: max pos
		uut.Register_File.register_file[6] = 32'hFFFFFFFF;   //                  vs -1
		uut.Register_File.register_file[7] = 32'h80000000;   // overflow case B: min neg
		uut.Register_File.register_file[8] = 32'd1;          //                  vs 1

		//          opcode rs    rt    rd    shamt funct
		load(0,  32'b000000_00001_00010_01010_00000_101010); // SLT R10, R1, R2   5 < 5        -> 0
		load(4,  32'b000000_00011_00100_01011_00000_101010); // SLT R11, R3, R4   5 < -3       -> 0
		load(8,  32'b000000_00100_00011_01100_00000_101010); // SLT R12, R4, R3   -3 < 5       -> 1
		load(12, 32'b000000_00101_00110_01101_00000_101010); // SLT R13, R5, R6   7FFFFFFF < -1 -> 0 (sub overflows)
		load(16, 32'b000000_00111_01000_01110_00000_101010); // SLT R14, R7, R8   80000000 < 1  -> 1 (sub overflows)
		load(20, 32'b000000_01000_00111_01111_00000_101010); // SLT R15, R8, R7   1 < 80000000  -> 0
		load(24, 32'b000100_00000_00000_11111_11111_11_1111);// BEQ R0,R0,-1  (park the PC)

		initialize = 0;
		rst = 0;
		#100;   // 6 instructions + margin

		check(10, 32'd0, "equal operands     ");
		check(11, 32'd0, "pos < neg          ");
		check(12, 32'd1, "neg < pos          ");
		check(13, 32'd0, "overflow 7FFFFFFF<-1");
		check(14, 32'd1, "overflow 80000000<1 ");
		check(15, 32'd0, "1 < 80000000       ");

		if (errors == 0) $display("ALL SLT TESTS PASSED");
		else             $display("%0d SLT TEST(S) FAILED", errors);
		$finish;
	end

	always #5 clk = ~clk;
endmodule
