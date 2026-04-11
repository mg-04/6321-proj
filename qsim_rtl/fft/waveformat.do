onerror {resume}
quietly WaveActivateNextPane {} 0


add wave -noupdate /testbench/clk
add wave -noupdate /testbench/rst

add wave -divider "Top Control"
add wave -noupdate -radix unsigned /testbench/dut/mode
add wave -noupdate -radix unsigned /testbench/dut/state
add wave -noupdate /testbench/dut/phase
add wave -noupdate -radix unsigned /testbench/dut/stage_cnt
add wave -noupdate -radix unsigned /testbench/dut/bf_cnt
add wave -noupdate -radix unsigned /testbench/dut/drain_cnt
add wave -noupdate /testbench/done

add wave -divider "Address Pipeline"
add wave -noupdate -radix binary /testbench/dut/valid_pipe
add wave -noupdate -radix hex /testbench/dut/addr_a
# Monitor the entrance and the exit of the pipe
add wave -noupdate -radix hex /testbench/dut/addr_a_pipe(0)
add wave -noupdate -radix hex /testbench/dut/addr_a_pipe(2)
add wave -noupdate -radix hex /testbench/dut/addr_a_pipe(4)
add wave -noupdate -radix hex /testbench/dut/actual_addr_a

add wave -divider "Memory Interface"
add wave -noupdate /testbench/dut/data_cen
add wave -noupdate /testbench/dut/data_gwen
add wave -noupdate -radix hex /testbench/dut/actual_addr_a
add wave -noupdate -radix hex /testbench/dut/actual_addr_b
add wave -noupdate -radix hex /testbench/dut/sram_din1
add wave -noupdate -radix hex /testbench/dut/sram_din2
add wave -noupdate -radix hex /testbench/dut/x0_data
add wave -noupdate -radix hex /testbench/dut/x1_data
add wave -noupdate -radix hex /testbench/dut/twiddle_data

add wave -divider "ALU Input Regs (Phase 1 Valid)"
add wave -noupdate -radix hex /testbench/dut/x0_reg
add wave -noupdate -radix hex /testbench/dut/x1_reg
add wave -noupdate -radix hex /testbench/dut/w_reg

add wave -divider "ALU Output (Writeback Data)"
add wave -noupdate -radix hex /testbench/dut/alu_out_X0
add wave -noupdate -radix hex /testbench/dut/alu_out_X1

add wave -divider "Testbench Readback"
add wave -noupdate /testbench/dread
add wave -noupdate -radix hex /testbench/daddr1
add wave -noupdate -radix hex /testbench/dout1

# --- 3. Final Formatting ---
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ns} {100 us}
