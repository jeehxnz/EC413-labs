# Lab 6: Execution Steps and Simulation per Instruction

All five instructions share the same first step: the PC addresses instruction memory, and control decodes instruction[31:26].

Run every command from the lab6 folder. In GTKWave, expand tb_NAME, then click uut to see its signals.

## SLT (e.g. SLT R12, R4, R3)

Simulate:
iverilog -o sim provided/*.v testbenches/tb_slt.v
vvp sim
gtkwave slt.vcd

1. The register file reads rs (R4) and rt (R3).
2. ALUSrc=0 passes R3 to the ALU's second input.
3. ALUOp=00, so ALU_control reads funct 0x2A and outputs function 5.
4. The ALU computes $signed(R4) < $signed(R3), which gives 1 or 0.
5. MemtoReg=0 and LUI=0, so the ALU result reaches write_data.
6. RegDst=1 selects rd (R12) as the destination.
7. On the clock edge, RegWrite stores the result in R12 and the PC loads PC+4.

## ADDI (e.g. ADDI R2, R2, -3)

Simulate:
iverilog -o sim provided/*.v testbenches/tb_addi.v
vvp sim
gtkwave addi.vcd

1. The register file reads rs (R2).
2. Sign-extend turns instruction[15:0] into a 32-bit immediate, so FFFD becomes -3.
3. ALUSrc=1 sends the immediate to the ALU's second input.
4. ALUOp=10, so ALU_control outputs function 0 (add) and ignores the instruction's low bits.
5. The ALU computes R2 + (-3).
6. MemtoReg=0 sends the ALU result to write_data.
7. RegDst=0 selects rt as the destination.
8. On the clock edge, RegWrite stores the result and the PC loads PC+4.

## J (e.g. J 4)

Simulate:
iverilog -o sim provided/*.v testbenches/tb_j.v
vvp sim
gtkwave j.vcd

1. The Jump_address wiring takes PC+4[31:28], then the 26-bit target instruction[25:0], then 00. For J 4 that gives 0x10.
2. The branch path still computes its candidate, but Jump=1 makes it irrelevant.
3. Jump_MUX selects the jump address as PC_in.
4. RegWrite=0 and MemWrite=0, so no register or memory changes.
5. On the clock edge, the PC loads the jump address.

## BNE (e.g. BNE R5, R0, -3)

Simulate:
iverilog -o sim provided/*.v testbenches/tb_bne.v
vvp sim
gtkwave bne.vcd

1. The register file reads rs (R5) and rt (R0).
2. ALUSrc=0 passes R0 to the ALU's second input.
3. ALUOp=01, so the ALU subtracts, and zero_flag is 1 if the two are equal.
4. In parallel, sign-extend and shift-left-2 turn the offset into a byte offset, and an adder gives the target PC+4 + offset*4.
5. PCSrc = (Branch & zero) | (BranchNE & ~zero). With BranchNE=1, it is 1 when the registers differ.
6. If PCSrc=1, the PC mux picks the branch target, otherwise PC+4. Jump=0, so that choice passes through.
7. RegWrite=0, so nothing is written. On the clock edge, the PC loads the chosen address.

## LUI (e.g. LUI R1, 0xA5C3)

Simulate:
iverilog -o sim provided/*.v testbenches/tb_lui.v
vvp sim
gtkwave lui.vcd

1. lui_value is built from instruction[15:0] followed by 16 zero bits, giving A5C30000.
2. The register file and ALU also compute something, but the result is ignored.
3. The MemtoReg mux outputs the ALU result, since MemtoReg=0.
4. LUI=1, so LUI_MUX overrides it and puts lui_value on write_data.
5. RegDst=0 selects rt (R1) as the destination.
6. On the clock edge, RegWrite stores A5C30000 and the PC loads PC+4.