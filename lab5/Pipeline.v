// 4-stage pipeline: S1 (instr latch) -> S2 (reg read) -> S3 (ALU) -> write-back.
// Data hazards are avoided in software with NOPs (no forwarding).
module Pipeline(InstrIn, Reset, Clk, WriteEnable, ALUOut);
    input  [31:0] InstrIn;
    input         Reset, Clk;
    input         WriteEnable;     // global write enable (ANDed with instruction's valid bit)
    output [31:0] ALUOut;          // registered ALU result (S3 output)

    // ---------- Stage 1: decode, then latch ----------
    wire [4:0]  D_RS1, D_RS2, D_WS;
    wire [15:0] D_Imm;
    wire        D_DataSrc, D_WE;
    wire [2:0]  D_ALUOp;
    Decode dec(InstrIn, D_RS1, D_RS2, D_WS, D_Imm, D_DataSrc, D_ALUOp, D_WE);

    wire [4:0]  S1_RS1, S1_RS2, S1_WS;
    wire [15:0] S1_Imm;
    wire        S1_DataSrc, S1_WE;
    wire [2:0]  S1_ALUOp;
    nbit_reg #(5)  r_s1_rs1 (D_RS1,     S1_RS1,     1'b1, Reset, Clk);
    nbit_reg #(5)  r_s1_rs2 (D_RS2,     S1_RS2,     1'b1, Reset, Clk);
    nbit_reg #(5)  r_s1_ws  (D_WS,      S1_WS,      1'b1, Reset, Clk);
    nbit_reg #(16) r_s1_imm (D_Imm,     S1_Imm,     1'b1, Reset, Clk);
    nbit_reg #(3)  r_s1_op  (D_ALUOp,   S1_ALUOp,   1'b1, Reset, Clk);
    nbit_reg #(1)  r_s1_src (D_DataSrc, S1_DataSrc, 1'b1, Reset, Clk);
    nbit_reg #(1)  r_s1_we  (D_WE & WriteEnable, S1_WE, 1'b1, Reset, Clk);

    // ---------- Stage 2: register file read, then latch ----------
    wire [31:0] RF_RD1, RF_RD2;
    wire [31:0] S3_ALUOut;  wire [4:0] S3_WS;  wire S3_WE;   // write-back (from Stage 3)

    nbit_register_file RegFile(
        .WriteData(S3_ALUOut), .ReadData1(RF_RD1), .ReadData2(RF_RD2),
        .ReadSelect1(S1_RS1), .ReadSelect2(S1_RS2),
        .WriteSelect(S3_WS), .WriteEnable(S3_WE), .Reset(Reset), .Clk(Clk));

    wire [31:0] S2_RD1, S2_RD2;
    wire [15:0] S2_Imm;
    wire [4:0]  S2_WS;
    wire [2:0]  S2_ALUOp;
    wire        S2_DataSrc, S2_WE;
    nbit_reg #(32) r_s2_rd1 (RF_RD1,     S2_RD1,     1'b1, Reset, Clk);
    nbit_reg #(32) r_s2_rd2 (RF_RD2,     S2_RD2,     1'b1, Reset, Clk);
    nbit_reg #(16) r_s2_imm (S1_Imm,     S2_Imm,     1'b1, Reset, Clk);
    nbit_reg #(5)  r_s2_ws  (S1_WS,      S2_WS,      1'b1, Reset, Clk);
    nbit_reg #(3)  r_s2_op  (S1_ALUOp,   S2_ALUOp,   1'b1, Reset, Clk);
    nbit_reg #(1)  r_s2_src (S1_DataSrc, S2_DataSrc, 1'b1, Reset, Clk);
    nbit_reg #(1)  r_s2_we  (S1_WE,      S2_WE,      1'b1, Reset, Clk);

    // ---------- Stage 3: operand MUX, ALU, then latch ----------
    wire [31:0] S2_Imm32 = {16'b0, S2_Imm};     // zero-extend immediate
    wire [31:0] ALU_B;                          // second ALU operand
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : operand_mux
            nbit_mux #(1) m ({S2_Imm32[i], S2_RD2[i]}, ALU_B[i], S2_DataSrc);
        end
    endgenerate

    wire [31:0] ALU_Out;
    Ideal_ALU alu(.R1(ALU_Out), .R2(S2_RD1), .R3(ALU_B), .ALUOp(S2_ALUOp));

    nbit_reg #(32) r_s3_out (ALU_Out, S3_ALUOut, 1'b1, Reset, Clk);
    nbit_reg #(5)  r_s3_ws  (S2_WS,   S3_WS,     1'b1, Reset, Clk);
    nbit_reg #(1)  r_s3_we  (S2_WE,   S3_WE,     1'b1, Reset, Clk);

    assign ALUOut = S3_ALUOut;
endmodule