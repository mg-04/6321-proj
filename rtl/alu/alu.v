// alu.v
// new alu model with rounding to the nearest even, 3dB better performance
module alu(
    input clk,
    input signed [15:0] x0r, x0i, x1r, x1i, wr, wi, // Q 3.13
    output signed [15:0] X0r0, X0i0, X1r0, X1i0     
);
    // DIF FFT, using sign extension just to be safe
    wire signed [16:0] sum_r  = {x0r[15], x0r} + {x1r[15], x1r};
    wire signed [16:0] sum_i  = {x0i[15], x0i} + {x1i[15], x1i};
    wire signed [16:0] diff_r = {x0r[15], x0r} - {x1r[15], x1r};
    wire signed [16:0] diff_i = {x0i[15], x0i} - {x1i[15], x1i};

    // X0 = (x0 + x1) / 2
    // round to nearst even: round up if (bit 0 is 1) AND (bit 1 is 1)
    assign X0r0 = (sum_r + (sum_r[0] & sum_r[1])) >>> 1;
    assign X0i0 = (sum_i + (sum_i[0] & sum_i[1])) >>> 1;

    // X1 = ((x0 - x1) * W) / 2, Q 7.26
    wire signed [32:0] p_rr = diff_r * wr;
    wire signed [32:0] p_ii = diff_i * wi;
    wire signed [32:0] p_ri = diff_r * wi;
    wire signed [32:0] p_ir = diff_i * wr;

    // raw output
    wire signed [33:0] X1r_full = p_rr - p_ii; // Q 8.26
    wire signed [33:0] X1i_full = p_ri + p_ir; // Q 8.26

    // Shift by 13 from multiplication + 1 (for scaling) = 14
    wire r_sticky = |X1r_full[12:0];
    // round if more than 0.5; or 0.5 and rounding to even
    wire r_round  = X1r_full[13] & (X1r_full[14] | r_sticky);
    assign X1r0 = (X1r_full[33:14] + r_round);

    wire i_sticky = |X1i_full[12:0];
    wire i_round  = X1i_full[13] & (X1i_full[14] | i_sticky);
    assign X1i0 = (X1i_full[33:14] + i_round);

endmodule