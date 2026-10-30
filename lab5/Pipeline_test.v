`timescale 1ns / 1ps
module Pipeline_test;
    reg [31:0] InstrIn;
    reg Reset, Clk, WriteEnable;
    wire [31:0] ALUOut;

    Pipeline uut(.InstrIn(InstrIn), .Reset(Reset), .Clk(Clk),
                 .WriteEnable(WriteEnable), .ALUOut(ALUOut));

    always #5 Clk = ~Clk;                       // 10 ns period

    localparam NOP = 32'b0;
    // Apply one instruction on the falling edge so it's stable at the next posedge
    task issue(input [31:0] instr);
        begin @(negedge Clk); InstrIn = instr; end
    endtask

    // Compare a register to its expected value (hierarchical path into the reg file)
    task check(input [4:0] r, input [31:0] expected);
        if (uut.RegFile.w_reg_to_outmux[r] !== expected)
            $display("FAIL r%0d = %h, expected %h", r, uut.RegFile.w_reg_to_outmux[r], expected);
        else
            $display("PASS r%0d = %h", r, expected);
    endtask

    initial begin
        InstrIn = 0; Reset = 1; Clk = 0; WriteEnable = 0;
        #100 Reset = 0; WriteEnable = 1;

        // Sample sequence from the lab handout
        issue(32'b011010_00001_00001_0000000000001010); // ADDI r1 = 0A
        issue(32'b011100_00010_00010_0000000000000010); // ORI  r2 = 02
        issue(32'b011010_00011_00011_0000000000000111); // ADDI r3 = 07
        issue(32'b011010_00110_00110_0000000011111111); // ADDI r6 = FF  (hazard spacer)
        issue(32'b010101_00100_00001_00010_00000000000); // AND  r4 = r1 & r2 = 02
        issue(32'b010011_00101_00001_00011_00000000000); // SUB  r5 = r1 - r3 = 03
        issue(NOP); issue(NOP); issue(NOP); issue(NOP); // drain the pipeline

        check(1, 32'h0000000A); check(2, 32'h00000002);
        check(3, 32'h00000007); check(4, 32'h00000002);
        check(5, 32'h00000003); check(6, 32'h000000FF);
        #50;        // let the waveform run past the last check
        $finish;
    end

    initial begin
        $dumpfile("Pipeline_test.vcd");   // output waveform file
        $dumpvars(0, Pipeline_test);      // record every signal in the testbench and below
    end

endmodule