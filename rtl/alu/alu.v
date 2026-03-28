module alu(
	input clk,		// unused
	input signed [15:0] x0r, x0i, x1r, x1i, wr, wi,		// Q 3.13
	output signed [15:0] X0r X0i, X1r, X1i
);

	// internal multiplication wires
	wire signed [31:0] prod_rr, prod_ii, prod_ri, prod_ir;
	wire signed [15:0] x1w_r, x1w_i;

	// compute x1 * W (Q 6.26)
	assign prod_rr = x1r * wr;
	assign prod_ri = x1r * wi;
	assign prod_ir = x1i * wr;
	assign prod_ii = x1i * wi;

	// Q 3.13 again
	assign x1w_r = (prod_rr - prod_ii) >>> 13; 
	assign x1w_i = (prod_ri + prod_ir) >>> 13;

	// X0 = (x0 + x1W) / 2
	// X1 = (x0 - x1W) / 2
	wire signed [16:0] sum_r, sum_i, diff_r, diff_i;
	assign sum_r  = x0r + x1w_r;
	assign sum_i  = x0i + x1w_i;
	assign diff_r = x0r - x1w_r;
	assign diff_i = x0i - x1w_i;

	// internal shift by 1 to save space
	assign X0r = sum_r >>> 1;
	assign X0i = sum_i >>> 1;
	assign X1r = diff_r >>> 1;
	assign X1i = diff_i >>> 1;
endmodule