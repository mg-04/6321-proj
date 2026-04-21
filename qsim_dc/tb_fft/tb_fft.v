`timescale 1ns/1ps
`define SD #0.010
`define HALF_CLOCK_PERIOD #1   // 500 MHz Clock
`define QSIM_OUT_FN "./qsim_fft.out"
`define TWIDDLE_FN  "../../matlab/FFT_input/twiddle_q15.hex" // 512 entries (all in 32-bit hex)
`define INPUT_FN    "../../matlab/FFT_input/input_q1_15_v3.hex"   // 1024 entries x 10
`define GOLDEN_FN   "../../matlab/FFT_input/output_q1_15.hex" // 1024 entries x 10
`define ALU_DEBUG_FN "alu_trace.txt"
`define SCALE_MASK   10'b1111001111         // MSB: later stage; LSB: early stage
// for Q1.15 input to Q9.7 output, make sure to have exactly 8 1s and 2 0s
// Earlier shifting results in lower accuracy, but less prone to overflow

module testbench();
    parameter N_POINTS = 1024;
    parameter W_POINTS = 512;
    parameter N_TESTS = 10;

    reg clk, rst, start;
    reg [1:0] mode;
    reg [9:0]  mux_addr;
    reg [31:0] dcin1;
    reg [31:0] din2;
    
    wire done;
    wire [31:0] dout1;
    wire [31:0] dout2;

    // file IO handling
    integer twiddle_file, input_file, golden_file, qsim_out_file, alu_log_file;
    integer i, test_idx, scan_ret, j;
    integer error_count = 0;
    
    reg [31:0] val_in1, val_in2;
    reg [31:0] gt_val1, gt_val2;

    fft dut (
        .clk(clk), .rst(rst), .start(start),
        .mode(mode),
        .mux_addr(mux_addr),
        .dcin1(dcin1), .din2(din2),
        .scale_mask(`SCALE_MASK),
        .done(done), .dout1(dout1), .dout2(dout2)
    );

    // clk generation
    initial clk = 0;
    always `HALF_CLOCK_PERIOD clk = ~clk;

    // main simulation
    initial begin
        $dumpfile("fft_tb.vcd");
        $dumpvars(0, testbench);

        // 1. Initialize
        rst = 0; start = 0; mode = 2'b00;
        mux_addr = 9'b0;
        dcin1 = 0; din2 = 0; 
        
        open_files();
        
        // one-time setup: master reset and load weights
        repeat (5) @(posedge clk);
        rst = 1;
        repeat (2) @(posedge clk);

        // 2. Load weights
        $display("Loading 512 weights...");
        mode <= 2'b01;		// CLOAD
		@(posedge clk);     // sync
        for (i = 0; i < W_POINTS; i = i + 1) begin
            scan_ret = $fscanf(twiddle_file, "%h\n", val_in1);
            @(negedge clk);
            mux_addr <= i[9:0];
            dcin1   <= val_in1;
        end
        @(negedge clk);
        mode <= 2'b00;

        // 1024 rounds of testing!!
        for (test_idx = 0; test_idx < N_TESTS; test_idx = test_idx + 1) begin
            $display("--- Starting Test Case %0d/%0d ---", test_idx + 1, N_TESTS);

            // 3. Load input data
            $display("Loading 1024 inputs...");
            mode <= 2'b10;		// DLOAD
            @(posedge clk);     // 2 syncs
            @(posedge clk);
            for (i = 0; i < N_POINTS; i = i + 2) begin
                scan_ret = $fscanf(input_file, "%h\n", val_in1);
                scan_ret = $fscanf(input_file, "%h\n", val_in2);
                @(negedge clk);
                mux_addr <= i[9:0];
                //daddr2 <= i[9:0] + 1'b1;
                dcin1 <= { val_in1[15:0], 16'b0 };        // imaginary parts is 0
                din2  <= { val_in2[15:0], 16'b0 };
            end
            @(negedge clk);
            mode <= 2'b00;

            // 4. start FFT, until done
            $display("STATUS: Starting FFT core...");
            @(negedge clk);
            start = 1;
            @(negedge clk);
            start = 0;

            wait(done == 1);
            $display("STATUS: FFT complete at %t", $time);

			@(negedge clk);

 			// 5. Read back from memory, verify output
			$display("STATUS: Verifying results...");

			mode <= 2'b11;      // DREAD
			@(negedge clk);
			mux_addr <= 10'd0;

			// prime the output pipeline (2 cycles of latency)
			@(negedge clk);

			mux_addr <= 10'd2;
			@(negedge clk);
			// output pipeline
			for (i = 0; i < N_POINTS; i = i + 2) begin
				scan_ret = $fscanf(golden_file, "%h\n", gt_val1);
				scan_ret = $fscanf(golden_file, "%h\n", gt_val2);

				if (dout1 !== gt_val1) begin
					$display("ERROR: Bit Mismatch at bin %0d! DUT1=%h, GT=%h", i, dout1, gt_val1);
					error_count = error_count + 1;
				end
				if (dout2 !== gt_val2) begin
					$display("ERROR: Bit Mismatch at bin %0d! DUT2=%h, GT=%h", i + 1, dout2, gt_val2);
					error_count = error_count + 1;
				end

				$fwrite(qsim_out_file, "%h\n", dout1);
				$fwrite(qsim_out_file, "%h\n", dout2);

				// prepare address for 2 cycles from now
				if (i + 4 < N_POINTS) begin
					mux_addr <= (i + 4); 
				end else if (i + 2 >= N_POINTS) begin
					mode <= 2'b00;
				end
				@(negedge clk);
			end
		end

        // report
        if (error_count == 0)
            $display("SUCCESS: 1024-point FFT passed perfectly.");
        else
            $display("FAILURE: FFT found %0d mismatches.", error_count);

        close_files();
        $dumpall;
        $dumpflush;
        $finish;
    end

    /*
    // helper function to debug ALU performance
    always @(posedge clk) begin
        // Only log when the FFT is actually performing a butterfly (WRITE state)
        // Adjust the path 'dut.state' to match your hierarchy
        if (dut.state == 4'd3) begin 
            $fwrite(alu_log_file, "%h %h %h %h %h\n", 
                    dut.x0_data,      // Input A
                    dut.x1_data,      // Input B
                    dut.twiddle_data, // Input W
                    dut.alu_out_X0,   // Output X0
                    dut.alu_out_X1);  // Output X1
        end
    end
    */ 

    // --- Helper Tasks ---
    task open_files;
        begin
            twiddle_file = $fopen(`TWIDDLE_FN, "r");
            input_file   = $fopen(`INPUT_FN, "r");
            golden_file  = $fopen(`GOLDEN_FN, "r");
            qsim_out_file = $fopen(`QSIM_OUT_FN, "w");
            alu_log_file = $fopen(`ALU_DEBUG_FN, "w");
            if (!twiddle_file || !input_file || !golden_file || !alu_log_file) begin
                $display("ERROR: Could not open one or more input files.");
                $finish;
            end
        end
    endtask

    task close_files;
        begin
            $fclose(twiddle_file);
            $fclose(input_file);
            $fclose(golden_file);
            $fclose(qsim_out_file);
            $fclose(alu_log_file);
        end
    endtask

	function [9:0] bit_rev;
		input [9:0] addr;
		integer k;
		begin
			for (k = 0; k < 10; k = k + 1)
				bit_rev[9-k] = addr[k];
		end
	endfunction

endmodule
