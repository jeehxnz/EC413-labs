`timescale 1ns/1ps
module dump;
  initial begin $dumpfile("fwd.vcd"); $dumpvars(0, fwd_tb); end
endmodule
