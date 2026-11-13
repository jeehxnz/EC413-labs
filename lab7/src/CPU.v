module CPU(out, clk, Reset, LoadInstructions, Instruction);

   output [31:0] out;
   input          Reset, LoadInstructions, clk;
   input [31:0]   Instruction;

   // ---------------------------------------------------------------------------
   // IF Wires
   // ---------------------------------------------------------------------------
   wire [31:0] PCIn, PCOut, IncrementedAddress, BranchAddress, InstructionOut;
   wire [31:0] LoadAddress, InstructionAddress, JumpAddress;
   wire        PCWrite, IF_Flush, IF_FlushorReset, IFID_Enable;
   wire [1:0]  PCSelect;

   // ---------------------------------------------------------------------------
   // IF/ID Wires
   // ---------------------------------------------------------------------------
   wire [31:0] IDEX_Instruction, IDEX_PC;

   // ---------------------------------------------------------------------------
   // ID Wires
   // ---------------------------------------------------------------------------
   wire        HazardMuxSelect;

   wire [5:0]  OpCode;
   assign OpCode = IDEX_Instruction[31:26];

   wire        RegDst, Equal, AluSrc, MemRead, MemWrite;
   wire        ZeroMuxSelect, RegWrite, MemToReg;
   wire [1:0]  AluOp;

   wire [5:0]  Funct;
   assign Funct = IDEX_Instruction[5:0];

   wire [1:0]  AluMux;
   wire        HiLoEnable;

   wire [1:0]  WBControl, MEMControl;
   wire [13:0] EXControl;

   wire [15:0] BOffset;
   assign BOffset = IDEX_Instruction[15:0];

   wire [25:0] JOffset;
   assign JOffset = IDEX_Instruction[25:0];

   wire        CompareOut;
   wire [4:0]  ReadReg1, ReadReg2;
   assign ReadReg1 = IDEX_Instruction[25:21];
   assign ReadReg2 = IDEX_Instruction[20:16];

   wire [31:0] RegSrcA, RegSrcB;
   wire [31:0] Immediate;
   wire [8:0]  AluCntrlOut;
   wire [4:0]  Shamt;
   assign Shamt = IDEX_Instruction[10:6];

   // ---------------------------------------------------------------------------
   // ID/EX Wires
   // ---------------------------------------------------------------------------
   wire [1:0]  IDEX_WBControl, IDEX_MEMControl;
   wire [13:0] IDEX_EXControl;
   wire [31:0] IDEX_A, IDEX_B;
   wire [31:0] IDEX_Immediate;
   wire [4:0]  IDEX_Rs, IDEX_Rt, IDEX_Rd;

   // ---------------------------------------------------------------------------
   // EX Wires
   // ---------------------------------------------------------------------------
   wire        MemReadEx;
   assign MemReadEx = IDEX_MEMControl[1];

   wire [1:0]  MuxASelect;
   wire [1:0]  MuxBSelect;
   wire [31:0] AluA, AluB, AluIB;

   wire        EX_AluSrc, EX_HiLoEnable, EX_RegDst;
   wire [8:0]  EX_AluCntrlOut;
   wire [1:0]  EX_AluMuxSelect;
   assign EX_HiLoEnable = IDEX_EXControl[0];
   assign EX_AluMuxSelect = IDEX_EXControl[2:1];
   assign EX_AluSrc = IDEX_EXControl[3];
   assign EX_AluCntrlOut = IDEX_EXControl[12:4];
   assign EX_RegDst = IDEX_EXControl[13];

   wire [31:0] AluResult, Hi, Lo, AluMuxResult;
   wire [31:0] HiRegOut, LoRegOut;
   wire [4:0]  RegDestMuxOut;

   // ---------------------------------------------------------------------------
   // EX/MEM Wires
   // ---------------------------------------------------------------------------
   wire [1:0]  EXMEM_WBControl;
   wire [1:0]  EXMEM_MEMControl;
   wire [31:0] MEM_Data_Raw;   // store data as carried in EX/MEM (after EX forwarding)
   wire [31:0] MEM_Data;       // store data actually written (after LW->SW forwarding)
   wire [4:0]  EXMEM_Rt;
   wire        ForwardStore;

   // ---------------------------------------------------------------------------
   // MEM Wires
   // ---------------------------------------------------------------------------
   wire [31:0] MemAluOut;
   wire [4:0]  MemDest;

   wire        MEM_RegWrite;
   assign MEM_RegWrite = EXMEM_WBControl[0];  // Used for forwarding data from MEM stage.

   wire        MEM_MemRead;
   wire        MEM_MemWrite;
   assign MEM_MemRead = EXMEM_MEMControl[1];
   assign MEM_MemWrite = EXMEM_MEMControl[0];

   wire [31:0] MemOut;

   // ---------------------------------------------------------------------------
   // MEM/WB Wires
   // ---------------------------------------------------------------------------
   wire [1:0]  WB_WBControl;
   wire [31:0] WBMemOut, WBAluOut;

   // ---------------------------------------------------------------------------
   // WB Wires
   // ---------------------------------------------------------------------------
   wire        RegWriteWB;
   assign RegWriteWB = WB_WBControl[0];

   wire        MemToRegSelect;
   assign MemToRegSelect = WB_WBControl[1];

   wire [31:0] WriteBackData;
   assign out = WriteBackData;
   wire [4:0] WriteBackDest;

   // ---------------------------------------------------------------------------
   // IF stage
   // ---------------------------------------------------------------------------
   reg_32bit PC (
      .out(PCOut),
      .in(PCIn),
      .enable(PCWrite),
      .reset(Reset),
      .clk(clk)
   );

   memory2 InstructionMem (
      .clk(clk),
      .mem_read(1'b1),
      .mem_write(LoadInstructions),
      .address(InstructionAddress),
      .data_in(Instruction),
      .data_out(InstructionOut)
   );

   mux2to1 AddressMux (
      .out(InstructionAddress),
      .in0(PCOut),
      .in1(LoadAddress),
      .sel(LoadInstructions)
   );

   load_in_counter AddressCounter (
      .countout(LoadAddress),
      .clk(clk),
      .reset(Reset)
   );

   incrementer Increment (
      .out(IncrementedAddress),
      .in(PCOut)
   );

   mux3to1_32bit BranchMux (
      .out(PCIn),
      .in0(IncrementedAddress),
      .in1(BranchAddress),
      .in2(JumpAddress),
      .select(PCSelect)
   );

   // ---------------------------------------------------------------------------
   // IF/ID pipeline register
   // ---------------------------------------------------------------------------
   reg_32bit IFID_PCReg (
      .out(IDEX_PC),
      .in(IncrementedAddress),
      .enable(IFID_Enable),
      .reset(IF_FlushorReset),
      .clk(clk)
   );

   or FlushOr (IF_FlushorReset, IF_Flush, Reset);

   reg_32bit IFID_InstructionReg (
      .out(IDEX_Instruction),
      .in(InstructionOut),
      .enable(IFID_Enable),
      .reset(IF_FlushorReset),
      .clk(clk)
   );

   // ---------------------------------------------------------------------------
   // ID stage
   // ---------------------------------------------------------------------------
   hazardunit HazardDetectionUnit (
      .IFIDWrite(IFID_Enable),
      .PCWrite(PCWrite),
      .HazardMux(HazardMuxSelect)
   );

   pipecontrol Control (
      .opcode(OpCode),
      .equal(Equal),
      .RegDst(RegDst),
      .AluOp(AluOp),
      .AluSrc(AluSrc),
      .BranchMux(PCSelect),
      .MemRead(MemRead),
      .MemWrite(MemWrite),
      .ZeroMux(ZeroMuxSelect),
      .RegWrite(RegWrite),
      .MemToReg(MemToReg),
      .IfFlush(IF_Flush)
   );

   multiplycontrol MultControl (
      .Opcode(OpCode),
      .Funct(Funct),
      .AluMux(AluMux),
      .HiLoEnable(HiLoEnable)
   );

   stallmux StalMux (
      .wb(WBControl),
      .m(MEMControl),
      .ex(EXControl),
      .MemToReg(MemToReg),
      .RegWrite(RegWrite),
      .MemRead(MemRead),
      .MemWrite(MemWrite),
      .RegDst(RegDst),
      .AluOp(AluCntrlOut),
      .AluSrc(AluSrc),
      .AluMux(AluMux),
      .HiLoEnable(HiLoEnable),
      .HazardMuxSelect(HazardMuxSelect)
   );

   jumpadd SmartAddressAdder (
      .BranchAddress(BranchAddress),
      .JOffset(JOffset),
      .BOffset(BOffset),
      .OpCode(OpCode),
      .IDEX_PC(IDEX_PC)
   );

   mux2to1_1bit ZeroMux (
      .out(Equal),
      .in0(CompareOut),
      .in1(~CompareOut),
      .sel(ZeroMuxSelect)
   );

   RegFile RegisterFile (
      .clk(clk),
      .reset(Reset),
      .WriteData(WriteBackData),
      .WriteRegister(WriteBackDest),
      .RegWrite(RegWriteWB),
      .ReadReg1(ReadReg1),
      .ReadReg2(ReadReg2),
      .ReadData1(RegSrcA),
      .ReadData2(RegSrcB)
   );

   signextend SignExtender (
      .extendout(Immediate),
      .in(BOffset)
   );

   signextend26 SignExtender26 (
      .extendout(JumpAddress),
      .in(IDEX_Instruction[25:0])
   );

   alucontrol AluCntrl (
      .funct(Funct),
      .opcode(OpCode),
      .aluop(AluOp),
      .shamt(Shamt),
      .aluout(AluCntrlOut)
   );

   // ---------------------------------------------------------------------------
   // ID/EX pipeline register 
   // ---------------------------------------------------------------------------
   reg_2bitne IDEX_WBReg (
      .out(IDEX_WBControl),
      .in(WBControl),
      .reset(Reset),
      .clk(clk)
   );

   reg_2bitne IDEX_MEMReg (
      .out(IDEX_MEMControl),
      .in(MEMControl),
      .reset(Reset),
      .clk(clk)
   );

   reg_14bitne IDEX_EXReg (
      .out(IDEX_EXControl),
      .in(EXControl),
      .reset(Reset),
      .clk(clk)
   );

   reg_32bitne IDEX_RegSrcA (
      .out(IDEX_A),
      .in(RegSrcA),
      .reset(Reset),
      .clk(clk)
   );

   reg_32bitne IDEX_RegSrcB (
      .out(IDEX_B),
      .in(RegSrcB),
      .reset(Reset),
      .clk(clk)
   );

   reg_32bitne IDEX_ImmediateReg (
      .out(IDEX_Immediate),
      .in(HazardMuxSelect ? 0 : Immediate),
      .reset(Reset),
      .clk(clk)
   );

   reg_5bitne IDEX_RsReg (
      .out(IDEX_Rs),
      .in(HazardMuxSelect ? 0 : IDEX_Instruction[25:21]),
      .reset(Reset),
      .clk(clk)
   );

   reg_5bitne IDEX_RtReg (
      .out(IDEX_Rt),
      .in(HazardMuxSelect ? 0 : IDEX_Instruction[20:16]),
      .reset(Reset),
      .clk(clk)
   );

   reg_5bitne IDEX_RdReg (
      .out(IDEX_Rd),
      .in(HazardMuxSelect ? 0 : IDEX_Instruction[15:11]),
      .reset(Reset),
      .clk(clk)
   );

   // ---------------------------------------------------------------------------
   // EX stage
   // ---------------------------------------------------------------------------
   mux2to1 ImmAluBMux (
      .out(AluIB),
      .in0(AluB),
      .in1(IDEX_Immediate),
      .sel(EX_AluSrc)
   );

   alu MarkAlu (
      .a(AluA),
      .b(AluIB),
      .aluop(EX_AluCntrlOut[3:0]),
      .shamt(EX_AluCntrlOut[8:4]),
      .result(AluResult),
      .hi(Hi),
      .lo(Lo)
   );

   reg_32bit HiReg (
      .out(HiRegOut),
      .in(Hi),
      .enable(EX_HiLoEnable),
      .reset(Reset),
      .clk(clk)
   );

   reg_32bit LoReg (
      .out(LoRegOut),
      .in(Lo),
      .enable(EX_HiLoEnable),
      .reset(Reset),
      .clk(clk)
   );

   mux3to1_32bit AluResultMux (
      .out(AluMuxResult),
      .in0(AluResult),
      .in1(HiRegOut),
      .in2(LoRegOut),
      .select(EX_AluMuxSelect)
   );

   mux2to1_5bit RegDstMux (
      .out(RegDestMuxOut),
      .in0(IDEX_Rt),
      .in1(IDEX_Rd),
      .sel(EX_RegDst)
   );
   
   // ---------------------------------------------------------------------------
   // Forwarding Unit
   // ---------------------------------------------------------------------------
   forwardingunit ForwardUnit (
      .ForwardA(MuxASelect),
      .ForwardB(MuxBSelect),
      .IDEX_Rs(IDEX_Rs),
      .IDEX_Rt(IDEX_Rt),
      .EXMEM_RegWrite(MEM_RegWrite),
      .EXMEM_Rd(MemDest),
      .MEMWB_RegWrite(RegWriteWB),
      .MEMWB_Rd(WriteBackDest)
   );

   // 00: register file value, 01: 2 ahead (write-back), 10: 1 ahead (EX/MEM ALU result)
   mux3to1_32bit ForwardAMux (
      .out(AluA),
      .in0(IDEX_A),
      .in1(WriteBackData),
      .in2(MemAluOut),
      .select(MuxASelect)
   );

   mux3to1_32bit ForwardBMux (
      .out(AluB),
      .in0(IDEX_B),
      .in1(WriteBackData),
      .in2(MemAluOut),
      .select(MuxBSelect)
   );

   // ---------------------------------------------------------------------------
   // EX/MEM pipeline register 
   // ---------------------------------------------------------------------------
   reg_2bitne EXMEM_WBReg (
      .out(EXMEM_WBControl),
      .in(IDEX_WBControl),
      .reset(Reset),
      .clk(clk)
   );

   reg_2bitne EXMEM_MEMReg (
      .out(EXMEM_MEMControl),
      .in(IDEX_MEMControl),
      .reset(Reset),
      .clk(clk)
   );

   reg_32bitne EXMEM_ALUReg (
      .out(MemAluOut),
      .in(AluMuxResult),
      .reset(Reset),
      .clk(clk)
   );

   reg_5bitne EXMEM_RegDest (
      .out(MemDest),
      .in(RegDestMuxOut),
      .reset(Reset),
      .clk(clk)
   );

   reg_32bitne EXMEM_MemData (
      .out(MEM_Data_Raw),
      .in(AluB),
      .reset(Reset),
      .clk(clk)
   );

   reg_5bitne EXMEM_RtReg (
      .out(EXMEM_Rt),
      .in(IDEX_Rt),
      .reset(Reset),
      .clk(clk)
   );

   // ---------------------------------------------------------------------------
   // MEM stage  (extra credit: LW -> SW store-data forwarding)
   // ---------------------------------------------------------------------------
   storeforward StoreFwd (
      .ForwardStore(ForwardStore),
      .MEM_MemWrite(MEM_MemWrite),
      .EXMEM_Rt(EXMEM_Rt),
      .MEMWB_RegWrite(RegWriteWB),
      .MEMWB_Rd(WriteBackDest)
   );

   mux2to1 StoreDataMux (
      .out(MEM_Data),
      .in0(MEM_Data_Raw),
      .in1(WriteBackData),
      .sel(ForwardStore)
   );

   memory2 DataMem (
      .clk(clk),
      .mem_read(MEM_MemRead),
      .mem_write(MEM_MemWrite),
      .address(MemAluOut),
      .data_in(MEM_Data),
      .data_out(MemOut)
   );

   // ---------------------------------------------------------------------------
   // MEM/WB pipeline register 
   // ---------------------------------------------------------------------------
   reg_2bitne MEMWB_WBControl (
      .out(WB_WBControl),
      .in(EXMEM_WBControl),
      .reset(Reset),
      .clk(clk)
   );

   reg_32bitne MEMWB_MemDataReg (
      .out(WBMemOut),
      .in(MemOut),
      .reset(Reset),
      .clk(clk)
   );

   reg_32bitne MEMWB_ALUReg (
      .out(WBAluOut),
      .in(MemAluOut),
      .reset(Reset),
      .clk(clk)
   );

   reg_5bitne MEMWB_DataMem (
      .out(WriteBackDest),
      .in(MemDest),
      .reset(Reset),
      .clk(clk)
   );

   // ---------------------------------------------------------------------------
   // WB stage
   // ---------------------------------------------------------------------------
   mux2to1 MemToRegMux (
      .out(WriteBackData),
      .in0(WBAluOut),
      .in1(WBMemOut),
      .sel(MemToRegSelect)
   );

endmodule
