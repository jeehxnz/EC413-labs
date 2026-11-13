`timescale 1ns / 1ps
// Self-checking testbench for Lab 7 (forwarding).  Runs the lab's 10-instruction
// sequence plus extra tests for $0 write, no-write, reg bypass, arbitration, LW->SW.
module fwd_tb;
   reg clk, Reset, LoadInstructions;
   reg [31:0] Instruction;
   wire [31:0] out;
   integer errors, n;

   CPU uut(.out(out), .clk(clk), .Reset(Reset), .LoadInstructions(LoadInstructions), .Instruction(Instruction));

   task put(input [31:0] i); begin Instruction = i; #10; end endtask
   function [31:0] rtype(input [5:0] f, input [4:0] rs, rt, rd);
      rtype = {6'd0, rs, rt, rd, 5'd0, f};
   endfunction
   function [31:0] itype(input [5:0] op, input [4:0] rs, rt, input [15:0] imm);
      itype = {op, rs, rt, imm};
   endfunction
   task chk(input [255:0] name, input [31:0] got, input [31:0] exp);
      begin
         if (got !== exp) begin errors = errors + 1; $display("FAIL %0s: got %0d expected %0d", name, got, exp); end
         else $display("ok   %0s = %0d", name, got);
      end
   endtask
   `define R(k) uut.RegisterFile.Reg_File[k]
   `define M(k) uut.DataMem.mem_array[k]
   localparam ADD=6'h20, SUB=6'h22, SLT=6'h2a, ADDI=6'd8, LW=6'd35, SW=6'd43;

   initial begin
      errors = 0; clk = 0; Reset = 1; LoadInstructions = 0; Instruction = 0; #10;
      Reset = 0; LoadInstructions = 1; #10;
      // ---- lab sequence (0..9)
      put(itype(ADDI,0,1,423));  put(itype(ADDI,0,2,92));  put(itype(ADDI,0,3,13));
      put(itype(ADDI,0,4,146));  put(itype(ADDI,0,5,5));
      put(rtype(ADD,1,4,5));     put(rtype(SLT,3,5,6));    put(rtype(SUB,4,6,7));
      put(itype(SW,0,7,0));      put(rtype(ADD,7,2,8));
      // ---- 10..: extra tests
      put(itype(ADDI,0,10,5));                 // 10 R10 = 5
      put(rtype(ADD,10,10,0));                 // 11 add $0,R10,R10  (write to $0 - must be ignored)
      put(rtype(ADD,0,10,11));                 // 12 R11 = $0 + R10 = 5   (15 if $0 wrongly forwarded)
      put(itype(SW,0,2,8));                    // 13 sw R2 -> mem[8]   (RegWrite=0, 'dest' field = R2)
      put(rtype(ADD,2,2,12));                  // 14 R12 = 184            (16 if sw result wrongly forwarded)
      put(itype(ADDI,0,13,3));                 // 15 R13 = 3
      put(32'd0); put(32'd0);                  // 16,17 nop nop
      put(rtype(ADD,13,13,14));                // 18 R14 = 6  (3-ahead: register-file bypass)
      put(itype(ADDI,0,15,1));                 // 19 R15 = 1
      put(itype(ADDI,15,15,2));                // 20 R15 = 3  (1 ahead)
      put(rtype(ADD,15,15,16));                // 21 R16 = 6  (both 1- and 2-ahead match: 1-ahead must win; 2 if wrong)
      put(itype(LW,0,17,8));                   // 22 lw R17, 8($0)  -> 92 (written by earlier sw)
      put(itype(SW,0,17,20));                  // 23 sw R17, 20($0) -> mem[20] = 92  (extra credit LW->SW)
      put(itype(LW,0,18,8));                   // 24 lw R18, 8($0)  -> 92
      put(32'd0);                              // 25 nop
      put(itype(SW,0,18,21));                  // 26 sw R18, 21($0) -> mem[21] = 92  (lw 2 ahead of sw)
      LoadInstructions = 0; Reset = 1; #10; Reset = 0;
      #400;
      $display("---- register file / memory checks ----");
      chk("R5  add fwd1",  `R(5), 569);
      chk("R6  slt fwd1",  `R(6), 1);
      chk("R7  sub fwd1",  `R(7), 145);
      chk("Mem[0] sw",     `M(0), 145);
      chk("R8  add fwd2",  `R(8), 237);
      chk("R0  stays 0",   `R(0), 0);
      chk("R11 \$0 no fwd", `R(11), 5);
      chk("Mem[8] sw",     `M(8), 92);
      chk("R12 no-write",  `R(12), 184);
      chk("R14 bypass",    `R(14), 6);
      chk("R16 arbitrate", `R(16), 6);
      chk("R17 lw",        `R(17), 92);
      chk("Mem[20] lw->sw",`M(20), 92);
      chk("Mem[21] lw,nop,sw", `M(21), 92);
      if (errors == 0) $display("ALL TESTS PASSED"); else $display("%0d FAILURES", errors);
      $finish;
   end
   always #5 clk = ~clk;
endmodule
