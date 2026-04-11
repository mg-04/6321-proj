// alu.v
// new alu model with rounding to the nearest even, 3dB better performance
module alu(
    input clk,
	input rst_n,
	input scale, 		// if 1, >> 1
    input signed [15:0] x0r, x0i, x1r, x1i, wr, wi, // Now all Q1.15
    output reg signed [15:0] X0r0, X0i0, X1r0, X1i0     
);
    // DIF FFT, using sign extension just to be safe
    wire signed [16:0] sum_r  = {x0r[15], x0r} + {x1r[15], x1r};
    wire signed [16:0] sum_i  = {x0i[15], x0i} + {x1i[15], x1i};
    wire signed [16:0] diff_r = {x0r[15], x0r} - {x1r[15], x1r};
    wire signed [16:0] diff_i = {x0i[15], x0i} - {x1i[15], x1i};

    // X1 = ((x0 - x1) * W) / 2, Q 7.26
    wire signed [32:0] p_rr = diff_r * wr;
    wire signed [32:0] p_ii = diff_i * wi;
    wire signed [32:0] p_ri = diff_r * wi;
    wire signed [32:0] p_ir = diff_i * wr;

    // raw output
    wire signed [33:0] X1r_full = p_rr - p_ii; // Q 8.26
    wire signed [33:0] X1i_full = p_ri + p_ir; // Q 8.26

	// shifting case
	// Shift by 15 from multiplication + 1 (for scaling) = 16
	wire r_sticky = |X1r_full[14:0];
	// round if more than 0.5; or 0.5 and rounding to even
	wire r_round  = X1r_full[15] & (X1r_full[16] | r_sticky);
	wire i_sticky = |X1i_full[14:0];
	wire i_round  = X1i_full[15] & (X1i_full[16] | i_sticky);

	// normal, non-shifting case, shift just by 15
	wire r_sticky2 = |X1r_full[13:0];
	wire r_round2 = X1r_full[14] & (X1r_full[15] | r_sticky2);
	wire i_sticky2 = |X1i_full[13:0];
	wire i_round2  = X1i_full[14] & (X1i_full[15] | i_sticky2);

	// new: sequential update
	always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            X0r0 <= 16'h0; X0i0 <= 16'h0;
            X1r0 <= 16'h0; X1i0 <= 16'h0;
        end else begin
            // Register X0
			// X0 = (x0 + x1) / 2
    		// round to nearst even: round up if (bit 0 is 1) AND (bit 1 is 1)
            if (scale) begin
                X0r0 <= (sum_r + (sum_r[0] & sum_r[1])) >>> 1;
                X0i0 <= (sum_i + (sum_i[0] & sum_i[1])) >>> 1;
            end else begin
                X0r0 <= sum_r[15:0];
                X0i0 <= sum_i[15:0];
            end

            // Register X1
            if (scale) begin
                X1r0 <= (X1r_full[31:16] + r_round);
                X1i0 <= (X1i_full[31:16] + i_round);
            end else begin
                X1r0 <= (X1r_full[30:15] + r_round2);
                X1i0 <= (X1i_full[30:15] + i_round2);
            end
        end
    end

endmodule