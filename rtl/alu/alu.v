module alu(
    input clk,
    input signed [15:0] x0r, x0i, x1r, x1i, wr, wi, // Q 3.13
    output signed [15:0] X0r0, X0i0, X1r0, X1i0     // avoid DC aliasing
);
    // DIF FFT
    wire signed [16:0] sum_r  = x0r + x1r;
    wire signed [16:0] sum_i  = x0i + x1i;
    wire signed [16:0] diff_r = x0r - x1r;
    wire signed [16:0] diff_i = x0i - x1i;

    // X0 = (x0 + x1) / 2
    // Round to Nearest: Add 1 (half of 2^1) before shifting down by 1
    assign X0r0 = (sum_r + 17'sd1) >>> 1;
    assign X0i0 = (sum_i + 17'sd1) >>> 1;

    // X1 = ((x0 - x1) * W) / 2, Q 6.26
    wire signed [32:0] p_rr = diff_r * wr;
    wire signed [32:0] p_ii = diff_i * wi;
    wire signed [32:0] p_ri = diff_r * wi;
    wire signed [32:0] p_ir = diff_i * wr;

    // Expand to 34 bits to prevent overflow, Q 7.26
    wire signed [33:0] X1r_full = p_rr - p_ii;
    wire signed [33:0] X1i_full = p_ri + p_ir;

    // Shift by 13 from multiplication + 1 (for scaling) = 14
    // Round to Nearest: Add 8192 (2^14/2)
    assign X1r0 = (X1r_full + 34'sd8192) >>> 14;
    assign X1i0 = (X1i_full + 34'sd8192) >>> 14;
endmodule