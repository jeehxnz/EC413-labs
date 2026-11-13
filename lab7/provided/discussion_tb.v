`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:39:32 03/21/2017 
// Design Name: 
// Module Name:    discussion_tb 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////
module discussion_tb;

   // Inputs
   reg clk;
   reg Reset;
   reg LoadInstructions;
   reg [31:0] Instruction;
   
   // Outputs
   wire [31:0] out;
   
   // Instantiate the Unit Under Test (UUT)
   CPU uut (
            .out(out), 
            .clk(clk), 
            .Reset(Reset), 
            .LoadInstructions(LoadInstructions), 
            .Instruction(Instruction)
            );
   
   initial begin
      // Initialize Inputs
      clk = 0;
      Reset = 1;
      LoadInstructions = 0;
      Instruction = 0;
      #10;
      
      Reset = 0;
      LoadInstructions = 1;
       #10;
      
      // 0
      Instruction = 32'b001000_00000_00001_0000000110100111; // 0x200101A7; addi $R1, $R0, 423
      #10;                                                   // $R1 = 423
      
      // 1
      Instruction = 32'b001000_00000_00010_0000000001011100; // 0x2002005C; addi $R2, $R0, 92  
      #10;                                                   // $R2 = 92

      // 2
      Instruction = 32'b001000_00000_00011_0000000000001101; // 0x2003000D; addi $R3, $R0, 13
      #10;                                                   // $R3 = 13

      // 3
      Instruction = 32'b001000_00000_00100_0000000010010010; // 0x20040092; addi $R4, $R0, 146
      #10;                                                   // $R4 = 146

      // 4
      Instruction = 32'b001000_00000_00101_0000000000000101; // 0x20050005; addi $R5, $R0, 5
      #10;                                                   // $R5 = 5

      // 5
      Instruction = 32'b000000_00001_00100_00101_00000_100000; // 0x00242820; add $R5, $R1, $R4
      #10;                                                      // $R5 = 423 + 146 = 569 (423 if wrong/no forwarding)

      // 6
      Instruction = 32'b000000_00011_00101_00110_00000_101010; // 0x0065302A; slt $R6, $R3, $R5
      #10;                                                      // $R6 = (13 < 569) = 1   (0 if wrong/no forwarding)

      // 7
      Instruction = 32'b000000_00100_00110_00111_00000_100010; // 0x00863822; sub $R7, $R4, $R6
      #10;                                                      // $R7 = 146 - 1 = 145 (146 if wrong)

      // 8
      Instruction = 32'b101011_00000_00111_0000000000000000; // 0xAC070000; sw $R7, 0($R0)
      #10;                                                    // Memory[0] = 145

      // 9
      Instruction = 32'b000000_00111_00010_01000_00000_100000; // 0x00E24020; add $R8, $R7, $R2
      #10;                                                      // $R8 = 145 + 92 = 237 (92 if wrong) 
      
      
     
      // LW - bonus
      // 10
      // Instruction = 32'b100011_00000_00100_0000000000000100; // 0x8C040004; lw $R4, 4($R0)
      // #10;                                                    // $R4 = Memory[4] = 4 (if initialized accordingly)

	  
      // 11
      // Instruction = 32'b000000_00100_00110_00111_00000_100010; // 0x00863822; sub $R7, $R4, $R6
      // #10;                                                      // $R7 = 4 - 1 = 3 


      
      LoadInstructions = 0;
      Reset = 1;
      #10;
		
      Reset = 0;
      #100;
      
   end
	
   always begin
      #5;
      clk = ~clk;
   end
   
endmodule
