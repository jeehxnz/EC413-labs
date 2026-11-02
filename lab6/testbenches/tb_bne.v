`timescale 1ns / 1ns

module tb_bne;
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
		$dumpfile("bne.vcd");
		$dumpvars(0, tb_bne);

		rst = 1; clk = 0; initialize = 1;
		instruction_initialize_data = 0;
		instruction_initialize_address = 0;
		#100;

		// registers start as R[i] = 10*i  (R2 = 20, R3 = 30, R6 = 60)
		load(0,  32'b001000_00000_00001_0000000000000001);   //  0: ADDI R1,R0,1
		load(4,  32'b000101_00001_00000_0000000000000001);   //  4: BNE R1,R0,+1   taken (1!=0) -> 12
		load(8,  32'b001000_00000_00010_0000000001100011);   //  8: ADDI R2,R0,99  (skipped)
		load(12, 32'b000101_00000_00000_0000000000000001);   // 12: BNE R0,R0,+1   NOT taken (0==0)
		load(16, 32'b001000_00000_00011_0000000000000101);   // 16: ADDI R3,R0,5   must execute
		load(20, 32'b001000_00000_00101_0000000000000011);   // 20: ADDI R5,R0,3   loop counter
		load(24, 32'b001000_00101_00101_1111111111111111);   // 24: ADDI R5,R5,-1  <- loop top
		load(28, 32'b001000_00110_00110_0000000000000001);   // 28: ADDI R6,R6,1   count iterations
		load(32, 32'b000101_00101_00000_1111111111111101);   // 32: BNE R5,R0,-3   backward -> 24
		load(36, 32'b001000_00000_00111_0000000000001001);   // 36: ADDI R7,R0,9   after loop
		load(40, 32'b000010_00000000000000000000001010);     // 40: J 40           (park PC)

		initialize = 0;
		rst = 0;
		#300;

		check(1, 32'd1,  "setup                ");
		check(2, 32'd20, "taken fwd skipped R2 ");
		check(3, 32'd5,  "not taken fell thru  ");
		check(5, 32'd0,  "loop counter hit 0   ");
		check(6, 32'd63, "backward loop 3 iters");
		check(7, 32'd9,  "loop exit falls thru ");
		if (uut.PC_out !== 32'd40) begin
			$display("FAIL PC parked at %0d, expected 40", uut.PC_out);
			errors = errors + 1;
		end else
			$display("PASS PC parked at 40");

		if (errors == 0) $display("ALL BNE TESTS PASSED");
		else             $display("%0d BNE TEST(S) FAILED", errors);
		$finish;
	end

	always #5 clk = ~clk;
endmodule
