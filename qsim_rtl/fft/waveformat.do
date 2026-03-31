onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/rst

add wave -divider "DUT I/O"
add wave -noupdate /testbench/start
add wave -noupdate /testbench/cload
add wave -noupdate /testbench/dload
add wave -noupdate /testbench/dread
add wave -noupdate -radix hex /testbench/caddr
add wave -noupdate -radix hex /testbench/daddr
add wave -noupdate -radix hex /testbench/cin
add wave -noupdate /testbench/done
add wave -noupdate -radix hex /testbench/dout

add wave -divider "DUT Internals"
add wave -noupdate -radix symbolic /testbench/dut/state
add wave -noupdate /testbench/dut/stage_cnt
add wave -noupdate /testbench/dut/i
add wave -noupdate /testbench/dut/stride
add wave -noupdate /testbench/dut/bf_cnt

add wave -divider "Data Memory Interface"
add wave -noupdate /testbench/dut/data_cen
add wave -noupdate /testbench/dut/data_gwen
add wave -noupdate -radix hex /testbench/dut/actual_addr_a
add wave -noupdate -radix hex /testbench/dut/actual_addr_b
add wave -noupdate -radix hex /testbench/dut/x0_data
add wave -noupdate -radix hex /testbench/dut/x1_data

add wave -divider "Weight Memory Interface"
add wave -noupdate /testbench/dut/weight_cen
add wave -noupdate /testbench/dut/weight_gwen
add wave -noupdate -radix hex /testbench/dut/actual_w_addr
add wave -noupdate -radix hex /testbench/dut/cin
add wave -noupdate -radix hex /testbench/dut/twiddle_data

add wave -divider "ALU Interface"
add wave -noupdate -radix hex /testbench/dut/alu_out_X0
add wave -noupdate -radix hex /testbench/dut/alu_out_X1

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
