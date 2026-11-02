`timescale 1ns / 1ns

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: dff
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module dff_tb;

	// Inputs
	reg d;
	reg clk;

	// Outputs
	wire q;

	// Instantiate the Unit Under Test (UUT)
	dff uut (
		.q(q), 
		.d(d), 
		.clk(clk)
	);

	initial begin
		// Initialize Inputs
		d = 0;
		clk = 0;
		#100;
		d = 1;
        #10;
		d= 0;
		#50;
		d=1;
		#150;
		d=0;
	end
      
always
#5 clk = ~clk;
endmodule

