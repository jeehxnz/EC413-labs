`timescale 1ns / 1ns
// 1-bit ALU slice
// Inputs : a, b      - one bit each of R2 and R3
//          cin       - carry in from the previous slice
//          binvert   - 1 = invert b before the adder (used for SUB and SLT)
//          slt_in    - SLT result bit, selected when ALUOp = 110
//          ALUOp[2:0]- selects the function (MOV,NOT,ADD,SUB,OR,AND,SLT)
// Outputs: result    - this bit of R1
//          cout      - carry out to the next slice
//          sum_out   - raw adder sum, before the MUX (used by the ALU for SLT)
module ALU_slice (result, cout, sum_out, a, b, cin, binvert, slt_in, ALUOp);

input        a, b, cin, binvert, slt_in;
input  [2:0] ALUOp;
output       result, cout, sum_out;

wire not_a, not_b, not_binvert;
wire b_keep, b_flip, b_adder;   
wire or_out, and_out;           

// b_adder = binvert ? ~b : b   (2-to-1 select built from gates)
not  n_b       (not_b, b);
not  n_binvert (not_binvert, binvert);
and  a_keep    (b_keep, b, not_binvert);
and  a_flip    (b_flip, not_b, binvert);
or   o_badder  (b_adder, b_keep, b_flip);

// Adder: ADD and SUB both use this sum
FA_str fa (.c_out(cout), .sum(sum_out), .a(a), .b(b_adder), .c_in(cin));

// Logic functions (use plain b, not the inverted one)
not  n_a   (not_a, a);
or   o_or  (or_out, a, b);
and  a_and (and_out, a, b);

// Select result: 0 MOV, 1 NOT, 2 ADD, 3 SUB, 4 OR, 5 AND, 6 SLT, 7 unused = 0
mux8_1bit mux (.y(result),
               .d({1'b0, slt_in, and_out, or_out, sum_out, sum_out, not_a, a}),
               .sel(ALUOp));

endmodule