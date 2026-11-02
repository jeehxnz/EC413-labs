`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:11:33 10/25/2016 
// Design Name: 
// Module Name:    cpu 
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
//////////////////////////////////////////////////////////////////////////////////

// 32 bit data
// 5 bit wide address for reg file
// 32 bit wide instruction
// 4 bit immediate

module cpu(
    rst,
	 clk,
	 initialize,
	 instruction_initialize_data,
	 instruction_initialize_address
    );
	 
	 	 
    input rst;
	 input clk;
	 input initialize;
	 input [31:0] instruction_initialize_data;
	 input [31:0] instruction_initialize_address;
	 wire [31:0] PC_out;
	 wire [31:0] instruction;
	 wire [31:0] instruction_mem_out;
	 assign instruction = (initialize) ? 32'hFFFF_FFFF : instruction_mem_out;
    InstrMem InstructionMemory (instruction_mem_out , instruction_initialize_data  , (initialize) ? instruction_initialize_address : PC_out , initialize , clk);
	
	
	
	 wire [1:0] ALUOp;
	 wire MemRead;
	 wire MemtoReg;
	 wire RegDst;
	 wire Branch; 
	 wire ALUSrc;
	 wire MemWrite;
	 wire RegWrite;
	 wire Jump;
	 wire BranchNE;
	 wire LUI;
    control Control(instruction [31:26], ALUOp, MemRead, MemtoReg, RegDst, Branch, ALUSrc, MemWrite, RegWrite, Jump, BranchNE, LUI); 
	 
	 
	 
	 wire           [31:0]            write_data;
    wire           [4:0]             write_register;
    wire		       [31:0]            read_data_1, read_data_2;
	 wire				 [31:0]            ALUOut, MemOut;
	 mux #(5) Write_Reg_MUX (RegDst, instruction[20:16], instruction[15:11], write_register);
	 nbit_register_file Register_File(write_data, read_data_1, read_data_2, instruction[25:21] , instruction[20:16], write_register, RegWrite, clk);
    
	 
	 
	 wire [31:0] immediate;
    sign_extend Sign_Extend( instruction[15:0], immediate);
	 
	 
	 
	 wire [31:0] ALU_input_2;
    wire zero_flag;
	 wire [2:0] ALU_function;
	 mux #(32) ALU_Input_2_Mux (ALUSrc, read_data_2, immediate, ALU_input_2);
	 ALU_control ALU_Control(instruction[5:0], ALUOp, ALU_function);
    ALU ALU(read_data_1, ALU_input_2, ALU_function, ALUOut, zero_flag);
	 
	 
	 Memory Data_Memory(ALUOut, read_data_2, MemOut, MemRead, MemWrite, clk);


    // Step 1 (original mux): MemtoReg=0 picks the ALU result, MemtoReg=1 picks memory data (lw).
    wire [31:0] alu_or_mem_data;
    mux #(32) ALU_Mem_Select_MUX (MemtoReg, ALUOut, MemOut, alu_or_mem_data);

    // Step 2 (new LUI MUX): the 16-bit immediate goes in the upper half, zeros fill the lower half.
    wire [31:0] lui_value;
    assign lui_value = {instruction[15:0], 16'b0};
    // LUI=1 overrides step 1 and writes lui_value; LUI=0 passes alu_or_mem_data through unchanged.
    mux #(32) LUI_MUX (LUI, alu_or_mem_data, lui_value, write_data);	 
	 
	 wire [31:0] PC_in;
	 PC Program_Counter(PC_out, PC_in, clk, rst);
	 
	 wire [31:0] PC_plus_4;
	 Adder #(32) PC_Increment_Adder (PC_out, 32'd4, PC_plus_4);


	 wire [31:0] Branch_target_address;
	 wire [31:0] immediate_x_4;
	 shift_left_2 #(32) Shift_Left_Two (immediate, immediate_x_4);
	 Adder #(32) Branch_Target_Adder (PC_plus_4, immediate_x_4, Branch_target_address);
	 
	 
	 // beq : Branch=1,   taken when zero_flag=1 (registers equal)
	 // bne : BranchNE=1, taken when zero_flag=0 (registers differ)
	 // Both use ALUOp=01 (subtract) so zero_flag means "equal".
	 // Branch and BranchNE are never both 1.
	 wire PCSrc;
	 assign PCSrc = (Branch & zero_flag) | (BranchNE & ~zero_flag);
	 wire [31:0] PC_next_seq_or_branch;
	 mux #(32) PC_Input_MUX (PCSrc, PC_plus_4, Branch_target_address, PC_next_seq_or_branch);

	 // Jump address = top 4 bits of PC+4, then the 26-bit target field, then 00.
	 wire [31:0] Jump_address;
	 assign Jump_address = {PC_plus_4[31:28], instruction[25:0], 2'b00};
	 // Jump=1 overrides the branch/sequential choice. The output is the PC's next value.
	 mux #(32) Jump_MUX (Jump, PC_next_seq_or_branch, Jump_address, PC_in);	 
	 
	 							 
endmodule
