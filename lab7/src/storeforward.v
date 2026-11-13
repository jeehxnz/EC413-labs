// -----------------------------------------------------------------------------
// Extra credit: LW followed by SW (store-data forwarding in the MEM stage).
// When a sw is in MEM and the instruction right before it (a lw/ALU op) is in WB
// writing the register that the sw stores, the store data is taken from the
// write-back data instead of the stale value carried in EX/MEM.  No stall needed.
// -----------------------------------------------------------------------------
module storeforward(ForwardStore, MEM_MemWrite, EXMEM_Rt, MEMWB_RegWrite, MEMWB_Rd);
   output ForwardStore;
   input        MEM_MemWrite, MEMWB_RegWrite;
   input  [4:0] EXMEM_Rt, MEMWB_Rd;

   assign ForwardStore = MEM_MemWrite && MEMWB_RegWrite &&
                         (MEMWB_Rd != 5'd0) && (MEMWB_Rd == EXMEM_Rt);
endmodule
