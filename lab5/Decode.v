// Decode: splits a 32-bit instruction into its fields. Purely combinational.
// Format: [31]unused [30]valid/WE [29]imm-select [28:26]ALUOp
//         [25:21]dest r1  [20:16]src r2  [15:11]src r3 (R) or [15:0]imm (I)
module Decode(InstrIn, ReadSelect1, ReadSelect2, WriteSelect,
              Imm, DataSrc, ALUOp, WriteEnable);
    input  [31:0] InstrIn;
    output [4:0]  ReadSelect1;   // first source register  (r2 field)
    output [4:0]  ReadSelect2;   // second source register (r3 field, ignored for I-type)
    output [4:0]  WriteSelect;   // destination register   (r1 field)
    output [15:0] Imm;           // immediate
    output        DataSrc;       // 0 = register operand, 1 = immediate
    output [2:0]  ALUOp;         // ALU function
    output        WriteEnable;   // 0 = NOP (no register write)

    assign WriteEnable = InstrIn[30];
    assign DataSrc     = InstrIn[29];
    assign ALUOp       = InstrIn[28:26];
    assign WriteSelect = InstrIn[25:21];
    assign ReadSelect1 = InstrIn[20:16];
    assign ReadSelect2 = InstrIn[15:11];
    assign Imm         = InstrIn[15:0];
endmodule