`timescale 1ns / 1ns

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//

// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: FA_str
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module FA_tb;

	// Inputs
	reg a;
	reg b;
	reg c_in;

	// Outputs
	wire c_out;
	wire sum;

	// Instantiate the Unit Under Test (UUT)
	FA_str uut (
		.c_out(c_out), 
		.sum(sum), 
		.a(a), 
		.b(b), 
		.c_in(c_in)
	);

	initial begin
		// Initialize Inputs
		a = 0;
		b = 0;
		c_in = 0;
		#100;
	end
      
	always
#10	{a,b,c_in} = {a,b,c_in}+1;
endmodule

