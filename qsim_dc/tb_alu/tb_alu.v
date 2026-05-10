`timescale 1ns/1ps
`define SD #0.010
`define HALF_CLOCK_PERIOD #1.25   // 400 MHz Clock
`define INPUT_FN  "alu_input.hex"
`define GOLDEN_FN "alu_golden.hex"
`define OUTPUT_FN "alu_out.out"

module testbench();
    // Test parameters
    parameter N_TESTS = 100; // Adjust based on your hex file size

    // DUT Signals
    reg clk;
    reg rst_n;
    reg scale;
    reg signed [15:0] x0r, x0i, x1r, x1i, wr, wi;
    wire signed [15:0] X0r0, X0i0, X1r0, X1i0;

    // Monitoring and File IO
    integer input_file, golden_file, out_file;
    integer i, scan_ret;
    integer error_count = 0;

    // Placeholder regs for golden data
    reg signed [15:0] gt_X0r, gt_X0i, gt_X1r, gt_X1i;

    // Instantiate DUT
    alu dut (
        .clk(clk),
        .rst_n(rst_n),
        .scale(scale),
        .x0r(x0r), .x0i(x0i), 
        .x1r(x1r), .x1i(x1i), 
        .wr(wr),   .wi(wi),
        .X0r0(X0r0), .X0i0(X0i0), 
        .X1r0(X1r0), .X1i0(X1i0)
    );

    // Clock Generation
    initial clk = 0;
    always `HALF_CLOCK_PERIOD clk = ~clk;

    // Main Simulation Block
    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, testbench);

        // 1. Initialize & Reset
        rst_n = 0;
        scale = 0;
        {x0r, x0i, x1r, x1i, wr, wi} = 0;
        
        open_files();

        repeat (5) @(posedge clk);
        `SD rst_n = 1;
        repeat (2) @(posedge clk);

        $display("STATUS: Starting ALU Verification...");

        // 2. Test Loop
        for (i = 0; i < N_TESTS; i = i + 1) begin
            // Read input vector and golden result
            // Format: scale x0r x0i x1r x1i wr wi
            scan_ret = $fscanf(input_file, "%b %h %h %h %h %h %h\n", 
                                scale, x0r, x0i, x1r, x1i, wr, wi);
            // Format: X0r0 X0i0 X1r0 X1i0
            scan_ret = $fscanf(golden_file, "%h %h %h %h\n", 
                                gt_X0r, gt_X0i, gt_X1r, gt_X1i);

            // Apply inputs on negedge
            @(negedge clk);
            
            // 3. Wait for 1 cycle latency
            // The ALU registers inputs on the next posedge, 
            // so we check the output on the subsequent negedge.
            @(negedge clk);

            // 4. Verify Results
            if ((X0r0 !== gt_X0r) || (X0i0 !== gt_X0i) || 
                (X1r0 !== gt_X1r) || (X1i0 !== gt_X1i)) begin
                $display("ERROR at Test %0d: Expected [%h, %h, %h, %h], Got [%h, %h, %h, %h]", 
                         i, gt_X0r, gt_X0i, gt_X1r, gt_X1i, X0r0, X0i0, X1r0, X1i0);
                error_count = error_count + 1;
            end

            // Log output
            $fwrite(out_file, "%h %h %h %h\n", X0r0, X0i0, X1r0, X1i0);
        end

        // 5. Final Report
        if (error_count == 0)
            $display("SUCCESS: ALU passed all %0d tests.", N_TESTS);
        else
            $display("FAILURE: ALU found %0d mismatches.", error_count);

        close_files();
        $finish;
    end

    // --- Helper Tasks ---
    task open_files;
        begin
            input_file  = $fopen(`INPUT_FN, "r");
            golden_file = $fopen(`GOLDEN_FN, "r");
            out_file    = $fopen(`OUTPUT_FN, "w");
            if (!input_file || !golden_file) begin
                $display("ERROR: Could not open vector files.");
                $finish;
            end
        end
    endtask

    task close_files;
        begin
            $fclose(input_file);
            $fclose(golden_file);
            $fclose(out_file);
        end
    endtask

endmodule