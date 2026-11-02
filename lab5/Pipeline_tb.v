`timescale 1ns / 1ps
// Self-checking testbench for Pipeline. A behavioral model (register array + ALU
// function) predicts every instruction's result. Each instruction is followed by
// NOPs so it fully completes before the next one starts (no data hazards).
module Pipeline_tb;

localparam [31:0] NOP = 32'b0;

reg  [31:0] InstrIn;
reg         Reset, Clk, WriteEnable;
wire [31:0] ALUOut;

Pipeline uut (.InstrIn(InstrIn), .Reset(Reset), .Clk(Clk),
              .WriteEnable(WriteEnable), .ALUOut(ALUOut));

// Clock: period 10 ns
initial Clk = 0;
always #5 Clk = ~Clk;

// Register file contents as plain wires
wire [31:0] R1 = uut.RegFile.w_reg_to_outmux[1];
wire [31:0] R2 = uut.RegFile.w_reg_to_outmux[2];
wire [31:0] R3 = uut.RegFile.w_reg_to_outmux[3];
wire [31:0] R4 = uut.RegFile.w_reg_to_outmux[4];
wire [31:0] R5 = uut.RegFile.w_reg_to_outmux[5];
wire [31:0] R6 = uut.RegFile.w_reg_to_outmux[6];

reg [31:0] model [0:31];     // expected register file contents
reg [31:0] corner [0:5];     // register values holding the corner operands
reg [4:0]  corner_reg [0:5]; // which register holds each corner value
reg [15:0] corner_imm [0:5]; // corner immediates
integer    errors, checks, op, i, j, k, r;

// Behavioral reference for the ALU
function [31:0] alu_ref(input [2:0] aop, input [31:0] a, input [31:0] b);
begin
	case (aop)
		3'h0: alu_ref = a;
		3'h1: alu_ref = ~a;
		3'h2: alu_ref = a + b;
		3'h3: alu_ref = a - b;
		3'h4: alu_ref = a | b;
		3'h5: alu_ref = a & b;
		3'h6: alu_ref = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
		default: alu_ref = 32'bx;
	endcase
end
endfunction

// Instruction builders (bit 31 unused, bit 30 valid, bit 29 immediate select)
function [31:0] rtype(input [2:0] aop, input [4:0] rd, input [4:0] rs, input [4:0] rt);
	rtype = {1'b0, 1'b1, 1'b0, aop, rd, rs, rt, 11'b0};
endfunction
function [31:0] itype(input [2:0] aop, input [4:0] rd, input [4:0] rs, input [15:0] imm);
	itype = {1'b0, 1'b1, 1'b1, aop, rd, rs, imm};
endfunction

// Compare every register in the DUT against the model
task check_regs;
begin
	for (r = 0; r < 32; r = r + 1) begin
		checks = checks + 1;
		if (uut.RegFile.w_reg_to_outmux[r] !== model[r]) begin
			errors = errors + 1;
			$display("ERROR t=%0t: r%0d = %h, expected %h", $time, r,
			         uut.RegFile.w_reg_to_outmux[r], model[r]);
		end
	end
end
endtask

// Issue one instruction on the falling edge, follow with NOPs, then check
// ALUOut (valid after the 3rd clock edge) and the register file (after the 4th).
task run_instr(input [31:0] instr);
	reg [31:0] a, b, expected;
begin
	a = model[instr[20:16]];
	b = instr[29] ? {16'b0, instr[15:0]} : model[instr[15:11]];
	expected = alu_ref(instr[28:26], a, b);

	@(negedge Clk);  InstrIn = instr;     // latched into Stage 1 at next posedge
	@(negedge Clk);  InstrIn = NOP;
	@(posedge Clk);                       // Stage 2 latch
	@(posedge Clk);  #1;                  // Stage 3 latch: ALUOut valid
	checks = checks + 1;
	if (ALUOut !== expected) begin
		errors = errors + 1;
		$display("ERROR t=%0t: instr=%h ALUOut=%h expected=%h", $time, instr, ALUOut, expected);
	end
	@(posedge Clk);  #1;                  // write-back into the register file
	if (instr[30] && WriteEnable) model[instr[25:21]] = expected;
	check_regs;
end
endtask

initial begin
	errors = 0;  checks = 0;
	InstrIn = NOP;  Reset = 1;  WriteEnable = 0;
	for (r = 0; r < 32; r = r + 1) model[r] = 0;
	#100 Reset = 0;  WriteEnable = 1;

	// ---- Build corner values in r1..r6 using only instructions ----
	run_instr(itype(3'h2, 5'd1, 5'd0, 16'd0));        // r1 = 0
	run_instr(itype(3'h2, 5'd2, 5'd0, 16'd1));        // r2 = 1
	run_instr(rtype(3'h1, 5'd3, 5'd1, 5'd0));         // r3 = ~0 = FFFFFFFF
	run_instr(itype(3'h2, 5'd4, 5'd0, 16'd2));        // r4 = 2
	run_instr(itype(3'h2, 5'd5, 5'd0, 16'd1));        // r5 = 1, doubled 31x -> 80000000
	for (k = 0; k < 31; k = k + 1) run_instr(rtype(3'h2, 5'd5, 5'd5, 5'd5));
	run_instr(rtype(3'h3, 5'd6, 5'd5, 5'd2));         // r6 = 80000000 - 1 = 7FFFFFFF

	corner_reg[0] = 1; corner_reg[1] = 2; corner_reg[2] = 3;
	corner_reg[3] = 6; corner_reg[4] = 5; corner_reg[5] = 4;
	corner_imm[0] = 16'h0000; corner_imm[1] = 16'h0001; corner_imm[2] = 16'hFFFF;
	corner_imm[3] = 16'h7FFF; corner_imm[4] = 16'h8000; corner_imm[5] = 16'h0002;

	// ---- Corner cases: every register pair, every function (R-type) ----
	for (op = 0; op < 7; op = op + 1)
		for (i = 0; i < 6; i = i + 1)
			for (j = 0; j < 6; j = j + 1)
				run_instr(rtype(op, 5'd7, corner_reg[i], corner_reg[j]));

	// ---- Corner cases: every register with every immediate (I-type) ----
	for (op = 0; op < 7; op = op + 1)
		for (i = 0; i < 6; i = i + 1)
			for (j = 0; j < 6; j = j + 1)
				run_instr(itype(op, 5'd8, corner_reg[i], corner_imm[j]));

	// ---- NOPs (bit 30 = 0) with otherwise valid fields must not write ----
	for (op = 0; op < 7; op = op + 1) begin
		run_instr(rtype(op, 5'd9,  5'd5, 5'd3) & ~(32'b1 << 30));
		run_instr(itype(op, 5'd10, 5'd5, 16'h1234) & ~(32'b1 << 30));
	end
	run_instr(NOP);

	// ---- Global WriteEnable low: valid instructions must not write either ----
	WriteEnable = 0;
	for (op = 0; op < 7; op = op + 1)
		run_instr(rtype(op, 5'd11, 5'd5, 5'd4));
	WriteEnable = 1;
	run_instr(rtype(3'h2, 5'd11, 5'd5, 5'd4));        // and writes again once enabled

	// ---- Random instructions (any register, either type, any function) ----
	for (k = 0; k < 500; k = k + 1) begin
		op = $unsigned($random) % 7;
		if ($random & 1) run_instr(itype(op, $random, $random, $random));
		else             run_instr(rtype(op, $random, $random, $random));
	end

	// ---- Reset clears the register file and pipeline registers ----
	@(negedge Clk);  Reset = 1;
	@(posedge Clk);  @(posedge Clk);  #1;
	for (r = 0; r < 32; r = r + 1) model[r] = 0;
	check_regs;
	checks = checks + 1;
	if (ALUOut !== 32'b0) begin
		errors = errors + 1;
		$display("ERROR t=%0t: ALUOut=%h after reset", $time, ALUOut);
	end
	Reset = 0;

	$display("DONE: %0d checks, %0d errors", checks, errors);
	if (errors == 0) $display("PASS");
	else             $display("FAIL");
	$finish;
end

initial begin
	$dumpfile("Pipeline_tb.vcd");
	$dumpvars(0, Pipeline_tb);
end

endmodule
