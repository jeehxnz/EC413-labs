// -----------------------------------------------------------------------------
// Forwarding unit (EX stage)
//
//  ForwardA / ForwardB select the ALU operand source:
//     2'b00 : value read from register file (ID/EX register)
//     2'b01 : "2 ahead" - write-back data   (MEM/WB stage, after MemToReg mux)
//     2'b10 : "1 ahead" - ALU result         (EX/MEM stage)
//
//  Task 4 (arbitration): if both the EX/MEM and MEM/WB instructions write the
//  register we need, the EX/MEM one (1 ahead) is the most recent value, so it wins.
//  Task 5 ($0 write): never forward for register $0 - it is always zero.
//  Task 6 (No write): never forward from an instruction whose RegWrite is 0
//  (sw, beq, bne, j, bubbles) even if its destination field matches.
// -----------------------------------------------------------------------------
module forwardingunit(ForwardA, ForwardB,
                      IDEX_Rs, IDEX_Rt,
                      EXMEM_RegWrite, EXMEM_Rd,
                      MEMWB_RegWrite, MEMWB_Rd);

   output [1:0] ForwardA, ForwardB;
   input  [4:0] IDEX_Rs, IDEX_Rt, EXMEM_Rd, MEMWB_Rd;
   input        EXMEM_RegWrite, MEMWB_RegWrite;

   // Task 2: 1-ahead hazards (producer in MEM stage)
   wire OneAheadA = EXMEM_RegWrite && (EXMEM_Rd != 5'd0) && (EXMEM_Rd == IDEX_Rs);
   wire OneAheadB = EXMEM_RegWrite && (EXMEM_Rd != 5'd0) && (EXMEM_Rd == IDEX_Rt);

   // Task 3: 2-ahead hazards (producer in WB stage)
   wire TwoAheadA = MEMWB_RegWrite && (MEMWB_Rd != 5'd0) && (MEMWB_Rd == IDEX_Rs);
   wire TwoAheadB = MEMWB_RegWrite && (MEMWB_Rd != 5'd0) && (MEMWB_Rd == IDEX_Rt);

   // Task 4: arbitration - 1 ahead has priority over 2 ahead
   assign ForwardA = OneAheadA ? 2'b10 : (TwoAheadA ? 2'b01 : 2'b00);
   assign ForwardB = OneAheadB ? 2'b10 : (TwoAheadB ? 2'b01 : 2'b00);

endmodule
