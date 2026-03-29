module fft (
	input clk, rst, start,
	input cload,	// load weight mode
	input dload,	// load data mode
	input dread,	// read data mode
	input [8:0] caddr,
	input [9:0] daddr,
	input signed [31:0] cin,
	output reg done,
	output [31:0] dout  // directly wired to sram output
);

	// control states
	localparam IDLE   = 4'd0,
               FETCH  = 4'd1,		// fetch, wait, write, next cycle
               WAIT   = 4'd2,
               WRITE  = 4'd3,
               NEXT   = 4'd4,
               DONE   = 4'd5,
			   CLOAD      = 4'd6,
			   DLOAD      = 4'd7,
			   DREAD      = 4'd8,
			   DREAD_WAIT = 4'd9;

    reg [3:0] state;
    reg [3:0] stage_cnt;    // FFT stage count
    reg [8:0] bf_cnt;       // 0 to 511

	// memory control signals
	reg data_cen, data_gwen;
	reg weight_cen, weight_gwen;
	reg [9:0] addr_a, addr_b;
	reg [8:0] w_addr;

	wire [9:0] stride = 10'd512 >> stage_cnt;	// starts at 512
	// find the pair of the butterfly
	wire [9:0] i = bf_cnt % stride;
	wire [9:0] group_start = (bf_cnt / stride) * (2 * stride);	// address offset for the current butterfly group

    reg [31:0] cin_reg;



	// data memory
	wire [31:0] x0_data, x1_data;       // Outputs from SRAM
	wire [31:0] alu_out_X0, alu_out_X1; // Outputs from ALU

	// Mux for SRAM data input during DLOAD mode
	wire [31:0] sram_din1 = (state == DLOAD) ? cin_reg : alu_out_X0;

	sram_wrapper02 data_mem (
		.clk(clk),
		.cen(data_cen),             // Controlled by FSM
		.gwen(data_gwen),           // 1 for Read, 0 for Write
		.addr1(addr_a), 
		.addr2(addr_b),
		.din1(sram_din1), 
		.din2(alu_out_X1),
		.dout1(x0_data), 
		.dout2(x1_data)
	);

    assign dout = (state == DREAD_WAIT || state == DREAD) ? x0_data : 32'h0;

	// weight memory
	wire [31:0] twiddle_data;       // Output to ALU

	wire [31:0] load_w_data = cin_reg;	// for cload mode
	sram_wrapper01 weight_mem (
		.clk(clk),
		.cen(weight_cen),           // Always 0 during FFT
		.gwen(weight_gwen),         // 1 during FFT, 0 during Loading
		.addr(w_addr), 
		.din(load_w_data), 
		.dout(twiddle_data)
	);

	alu butterfly_unit (
		// data input read from sram
		.clk(clk),
		.x0r(x0_data[31:16]), .x0i(x0_data[15:0]),
		.x1r(x1_data[31:16]), .x1i(x1_data[15:0]),

		// twiddle inputs
		.wr(twiddle_data[31:16]), .wi(twiddle_data[15:0]),

		// result writeback
		.X0r(alu_out_X0[31:16]), .X0i(alu_out_X0[15:0]),
		.X1r(alu_out_X1[31:16]), .X1i(alu_out_X1[15:0])
	);

	// control FSM
	always @(posedge clk or negedge rst) begin
		if (~rst) begin
			state <= IDLE;
			stage_cnt <= 0;
			bf_cnt <= 0;
			done <= 0;
			data_cen <= 1;
			data_gwen <= 1;
			weight_cen <= 1;
			weight_gwen <= 1;
			// dout <= 0;
            cin_reg <= 0;
		end else begin
            cin_reg <= cin;
			case (state)
				IDLE: begin
					done <= 0;
					data_cen <= 1;
					weight_cen <= 1;

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
						weight_gwen <= 1; // Set to read mode for FFT
					end
				end

				FETCH: begin
					// read from data memory
					data_cen <= 0;
					data_gwen <= 1;
					addr_a <= group_start + i;
					addr_b <= group_start + i + stride;

					// read from weight memory
					weight_cen <= 0;
					// weight_gwen is already set to 1 (read mode)
					w_addr <= i << stage_cnt;	// TODO

					state <= WAIT;
				end

				WAIT: begin
					// wait for a cycle for SRAM to read
					state <= WRITE;
				end

				WRITE: begin
					data_cen <= 0;
					data_gwen <= 0;
					// written from ALU
					state <= NEXT;
				end

				NEXT: begin			// update indices
					data_gwen <= 1;
					weight_cen <= 1; // De-assert chip enable for weight mem
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
					data_cen <= 1;
					state <= IDLE;
				end

				CLOAD: begin
					weight_cen <= 0;
					weight_gwen <= 0; // Write mode
					w_addr <= caddr;
					if (!cload) begin
						state <= IDLE;
						weight_gwen <= 1; // back to read mode
					end
				end

				DLOAD: begin
					data_cen <= 0;
					data_gwen <= 0; // Write mode
					addr_a <= daddr;
					if (!dload) begin
						state <= IDLE;
						data_gwen <= 1; // back to read mode
					end
				end

				DREAD: begin
					data_cen <= 0;
					data_gwen <= 1; // Read mode
					addr_a <= daddr;
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
