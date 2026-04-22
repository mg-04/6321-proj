module fft (
	input clk, rst, start,
	input [1:0] mode,	// 00: IDLE, 01: CLOAD, 10: DLOAD, 11: DREAD
	input [9:0] mux_addr,
	input signed [31:0] dcin1,
	input signed [31:0] din2,
	input [9:0] scale_mask,
	output reg done,
	output reg [31:0] dout1,  // directly wired to sram output
	output reg [31:0] dout2
);
	// input unpacking
	wire cload = (mode == 2'b01);
    wire dload = (mode == 2'b10);
    wire dread = (mode == 2'b11);

	wire [8:0] caddr  = mux_addr[8:0];
    wire [9:0] daddr1 = mux_addr;
    wire [9:0] daddr2 = mux_addr + 1'b1;
	// assume always reading parallel ports!

	wire [31:0] cin  = dcin1[31:0];
    wire [31:0] din1 = dcin1[31:0]; // Top 32 bits

	// control states
	localparam IDLE   = 4'd0,
               FFT_RUN = 4'd1,
			   FFT_DRAIN = 4'd2,	// stop new reads, continue pipeline
               DONE   = 4'd5,
			   CLOAD      = 4'd6,
			   DLOAD      = 4'd7,
			   DREAD      = 4'd8,	// prepare address
			   DREAD_WAIT = 4'd9;	// data available
    reg [3:0] state;
	reg phase;				// 0 for read cycle, 1 for write cycle

	// state count registers
    reg [3:0] stage_cnt;    // FFT stage count
    reg [8:0] bf_cnt;       // 0 to 511
	reg [2:0] drain_cnt;	// small counter to drain pipeline at the end

	// combinatorial address calculation from stage and bf
	wire scale = (scale_mask >> stage_cnt) & 1;
	wire [9:0] stride = 10'd512 >> stage_cnt;	// starts at 512
	// find the pair of the butterfly
	// faster way to compute modulo
	wire [9:0] mask = stride - 1'b1;
	wire [9:0] i = bf_cnt & mask;
	wire [9:0] group_start = (bf_cnt & ~(stride - 1)) << 1;

	wire [8:0] w_addr = i << stage_cnt;
	wire [9:0] addr_a = group_start + i;
	wire [9:0] addr_b = group_start + i + stride;

	// pipeline registers
	reg [9:0] addr_a_pipe [0:4];	// 4 + 1 cycles, need register for each
	reg [9:0] addr_b_pipe [0:4];
	reg [4:0] valid_pipe;	

	wire valid_read = (state == FFT_RUN && phase == 0) ? 1'b1 : 1'b0;
	// stop reading at draining stage

	// pipeline register updates
	integer k;
	always @(posedge clk or negedge rst) begin
		if (~rst)
			valid_pipe <= 5'b0;
		else if (state == FFT_RUN || state == FFT_DRAIN) begin
			valid_pipe <= {valid_pipe[2:0], 1'b0, valid_read};

			addr_a_pipe[0] <= addr_a;
			addr_b_pipe[0] <= addr_b;
			for (k = 2; k < 5; k = k + 1) begin
				addr_a_pipe[k] <= addr_a_pipe[k-2];
				addr_b_pipe[k] <= addr_b_pipe[k-2];
			end
		end else
			valid_pipe <= 5'b0;
	end

	wire is_fft_write = (state == FFT_RUN || state == FFT_DRAIN) && (phase == 1);

	// if next cycle will write, prepare write address for the head (4)
	// if next cycle will read, prepare address for the incoming guest (addr)
	wire [9:0] actual_addr_a = (state == DLOAD || state == DREAD) ? daddr1 : 
								(is_fft_write) ? addr_a_pipe[4] : addr_a;
	wire [9:0] actual_addr_b = (state == DLOAD || state == DREAD) ? daddr2 : 
								(is_fft_write) ? addr_b_pipe[4] : addr_b;
	wire [8:0] actual_w_addr = (state == CLOAD) ? caddr : w_addr;

	// memory control signals
	wire data_cen = (state == IDLE || state == CLOAD) ? 1'b1 : 1'b0;
	wire data_gwen = (state == DLOAD) ? 1'b0 : 
		(is_fft_write && valid_pipe[4]) ? 1'b0 : 1'b1;
	wire weight_cen = (state == IDLE || state == DLOAD || state == DREAD) ? 1'b1 : 1'b0;
	wire weight_gwen = (state == CLOAD) ? 1'b0 : 1'b1;

	// ALU-memory data path
	wire [31:0] x0_data, x1_data;       // Outputs from SRAM to ALU
	wire [31:0] twiddle_data;       // Output to ALU
	reg  [31:0] x0_reg, x1_reg, w_reg;	// registers for ALU input
	reg scale_reg;
	wire [31:0] alu_out_X0, alu_out_X1; // Outputs from ALU

	always @(posedge clk) begin
		if (state == FFT_RUN || state == FFT_DRAIN) begin
			if (phase == 1) begin // SRAM read was requested on phase 0, valid now
				x0_reg <= x0_data;
				x1_reg <= x1_data;
				w_reg  <= twiddle_data;
				scale_reg <= scale;
			end
		end
	end

	// Mux for IO during external modes
	wire [31:0] sram_din1 = (state == DLOAD) ? din1 : alu_out_X0;
	wire [31:0] sram_din2 = (state == DLOAD) ? din2 : alu_out_X1;

	// output assignment
	always @(posedge clk or negedge rst) begin
		if (~rst) begin
			dout1 <= 32'h0;
			dout2 <= 32'h0;
		end else begin
			// We only drive dout when in DREAD mode to save power/noise
			if (state == DREAD || state == DREAD_WAIT) begin
				dout1 <= x0_data;
				dout2 <= x1_data;
			end else begin
				dout1 <= 32'h0;
				dout2 <= 32'h0;
			end
		end
	end


	sram_wrapper02 data_mem (
		.clk(clk),
		.cen1(data_cen),             // Controlled by FSM
		.cen2(data_cen),	// only load from port 1
		.gwen1(data_gwen),           // 1 for Read, 0 for Write
		.gwen2(data_gwen),
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
		.rst_n(rst),
		.scale(scale),
		.x0r(x0_reg[31:16]), .x0i(x0_reg[15:0]),
		.x1r(x1_reg[31:16]), .x1i(x1_reg[15:0]),

		// twiddle inputs
		.wr(w_reg[31:16]), .wi(w_reg[15:0]),

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
			phase <= 0;
			done <= 0;
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
						state <= FFT_RUN;
						stage_cnt <= 0;
						bf_cnt <= 0;		// points at HEAD of pipeline
						phase <= 0;
					end
				end

				FFT_RUN: begin
					phase <= ~phase;
					
					if (phase == 1) begin	// need write at NEXT cycle
						if (bf_cnt == 511) begin
							state <= FFT_DRAIN;
							drain_cnt <= 0;
						end else begin
							bf_cnt <= bf_cnt + 1;
						end
					end 
				end

				FFT_DRAIN: begin
					phase <= ~phase;
					if (drain_cnt == 3) begin	// drain out last 4 stages
                        if (stage_cnt == 9) begin
                            state <= DONE;
                        end else begin
                            stage_cnt <= stage_cnt + 1;
                            bf_cnt <= 0;
                            state <= FFT_RUN; // Next cycle will be phase 0 (READ)
							phase <= 0;
                        end
                    end else begin
                        drain_cnt <= drain_cnt + 1;
                    end
				end

				DONE: begin
					done <= 1;
					state <= IDLE;
				end

				CLOAD: begin
					if (!cload) begin
						state <= IDLE;
					end
				end

				DLOAD: begin
					if (!dload) begin
						state <= IDLE;
					end
				end

				DREAD: begin
					if (!dread) state <= IDLE;
				end

				DREAD_WAIT: begin
					state <= dread ? DREAD : IDLE;
				end
			endcase
		end
	end
endmodule
