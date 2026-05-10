onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate /testbench/clk
add wave -noupdate /testbench/rst_n

add wave -divider "Inputs"
add wave -noupdate /testbench/scale
add wave -noupdate -radix hex /testbench/x0r
add wave -noupdate -radix hex /testbench/x0i
add wave -noupdate -radix hex /testbench/x1r
add wave -noupdate -radix hex /testbench/x1i
add wave -noupdate -radix hex /testbench/wr
add wave -noupdate -radix hex /testbench/wi

add wave -divider "DUT Outputs"
add wave -noupdate -radix hex /testbench/X0r0
add wave -noupdate -radix hex /testbench/X0i0
add wave -noupdate -radix hex /testbench/X1r0
add wave -noupdate -radix hex /testbench/X1i0

add wave -divider "Golden Reference"
add wave -noupdate -radix hex /testbench/gt_X0r
add wave -noupdate -radix hex /testbench/gt_X0i
add wave -noupdate -radix hex /testbench/gt_X1r
add wave -noupdate -radix hex /testbench/gt_X1i

add wave -divider "Status"
add wave -noupdate -radix decimal /testbench/error_count

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1

configure wave -namecolwidth 200
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns

update
WaveRestoreZoom {0 ns} {200 ns}