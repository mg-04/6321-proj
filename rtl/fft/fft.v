module fft (
	input clk, rst, start,
	input cload,	// load weight mode
	input dload,	// load data mode
	input dread,	// read data mode
	input [8:0] caddr,
	input [9:0] daddr,
	input signed [31:0] cin,
	input [9:0] scale_mask,
	output reg done,
	output wire [31:0] dout  // directly wired to sram output
);

	// control states
	localparam IDLE   = 4'd0,
               FETCH  = 4'd1,		// fetch, write cycle
               WRITE  = 4'd3,
               DONE   = 4'd5,
			   CLOAD      = 4'd6,
			   DLOAD      = 4'd7,
			   DREAD      = 4'd8,
			   DREAD_WAIT = 4'd9;
    reg [3:0] state;

    reg [3:0] stage_cnt;    // FFT stage count
    reg [8:0] bf_cnt;       // 0 to 511
	wire scale = (scale_mask >> stage_cnt) & 1;
	wire [9:0] stride = 10'd512 >> stage_cnt;	// starts at 512
	// find the pair of the butterfly
	wire [9:0] i = bf_cnt % stride;
	wire [9:0] group_start = (bf_cnt / stride) * (2 * stride);	// address offset for the current butterfly group

	// addr calculation
	wire [9:0] addr_a, addr_b;
	wire [8:0] w_addr;
	assign addr_a = group_start + i;
	assign addr_b = group_start + i + stride;
	assign w_addr = i << stage_cnt;
	wire [9:0] actual_addr_a = (state == DLOAD || state == DREAD || state == DREAD_WAIT) ? daddr : addr_a;
	wire [9:0] actual_addr_b = (state == DLOAD) ? daddr : addr_b;
	wire [8:0] actual_w_addr = (state == CLOAD) ? caddr : w_addr;

	// memory control signals
	wire data_cen = (state == IDLE || state == CLOAD) ? 1'b1 : 1'b0;
	wire data_gwen = (state == DLOAD || state == WRITE) ? 1'b0 : 1'b1;
	wire weight_cen = (state == IDLE || state == DLOAD || state == DREAD || state == DREAD_WAIT) ? 1'b1 : 1'b0;
	wire weight_gwen = (state == CLOAD) ? 1'b0 : 1'b1;

	// ALU-memory data path
	wire [31:0] x0_data, x1_data;       // Outputs from SRAM to ALU
	wire [31:0] twiddle_data;       // Output to ALU
	wire [31:0] alu_out_X0, alu_out_X1; // Outputs from ALU

	// Mux for IO during external modes
	wire [31:0] sram_din1 = (state == DLOAD) ? cin : alu_out_X0;
	wire [31:0] sram_din2 = (state == DLOAD) ? cin : alu_out_X1;
    assign dout = (state == DREAD_WAIT || state == DREAD) ? x0_data : 32'h0;

	sram_wrapper02 data_mem (
		.clk(clk),
		.cen1(data_cen),             // Controlled by FSM
		.cen2(state == DLOAD ? 1'b1 : data_cen),	// only load from port 1
		.gwen1(data_gwen),           // 1 for Read, 0 for Write
		.gwen2(state == DLOAD ? 1'b1 : data_gwen),
		.addr1(actual_addr_a), 
		.addr2(actual_addr_b),
		.din1(sram_din1), 
		.din2(sram_din2),
		.dout1(x0_data), 
		.dout2(x1_data)
	);
	sram_wrapper01 weight_mem (
		.clk(clk),
		.cen(weight_cen),           // Always 0 during FFT
		.gwen(weight_gwen),         // 1 during FFT, 0 during Loading
		.addr(actual_w_addr), 
		.din(cin), 
		.dout(twiddle_data)
	);

	alu butterfly_unit (
		// data input read from sram
		.clk(clk),
		.scale(scale),
		.x0r(x0_data[31:16]), .x0i(x0_data[15:0]),
		.x1r(x1_data[31:16]), .x1i(x1_data[15:0]),

		// twiddle inputs
		.wr(twiddle_data[31:16]), .wi(twiddle_data[15:0]),

		// result writeback
		.X0r0(alu_out_X0[31:16]), .X0i0(alu_out_X0[15:0]),
		.X1r0(alu_out_X1[31:16]), .X1i0(alu_out_X1[15:0])
	);

	// control FSM
	always @(posedge clk or negedge rst) begin
		if (~rst) begin
			state <= IDLE;
			stage_cnt <= 0;
			bf_cnt <= 0;
			done <= 0;
			// dout <= 0;	
		end else begin
			case (state)
				IDLE: begin
					done <= 0;
					if (cload) begin
						state <= CLOAD;
					end else if (dload) begin
						state <= DLOAD;
					end else if (dread) begin
						state <= DREAD;
					end else if (start) begin
						state <= FETCH;
						stage_cnt <= 0;
						bf_cnt <= 0;
					end
				end

				FETCH: begin
					// read happens on next edge
					// wires handled combinatorially
					state <= WRITE;
				end

				WRITE: begin
					// write happens on next edge
					// update count registers for next FETCH cycle
					if (bf_cnt == 511) begin	// all 512 pairs done
						bf_cnt <= 0;
						if (stage_cnt == 9) begin	// all 10 stages done
							state <= DONE;
						end else begin
							stage_cnt <= stage_cnt + 1;
							state <= FETCH;
						end
					end else begin
						bf_cnt <= bf_cnt + 1;
						state <= FETCH;
					end
				end

				DONE: begin
					done <= 1;
					state <= IDLE;
				end

				CLOAD: begin

					//w_addr <= caddr;
					if (!cload) begin
						state <= IDLE;
					end
				end

				DLOAD: begin

					//addr_a <= daddr;
					if (!dload) begin
						state <= IDLE;
					end
				end

				DREAD: begin

					//addr_a <= daddr;
					state <= DREAD_WAIT;
				end

				DREAD_WAIT: begin
					// dout <= x0_data; // Latch output
					// If dread is still high, start a new read, otherwise go idle
					state <= dread ? DREAD : IDLE;
				end
			endcase
		end
	end
endmodule
