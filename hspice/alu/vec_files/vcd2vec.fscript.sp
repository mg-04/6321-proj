* Convert vcd file to vec file 
load vcd ../../../qsim_apr/tb_alu/alu_tb.vcd
open ./test.vec

* These commands make the vector file's io to directly print the signal names 
* without the prefix scope as set in fset scope
fset scope testbench.dut
fset vcd2vec ascope

* First time point to start vector stimuli, e.g., could be positive clock edge
fset start 9.8e-9
* step = 2 clock cycles (ALU pipeline depth) at 200 MHz (5 ns period)
fset step 10.0e-9

* Input signal's logic high/low volages, i.e., hspice stimuli will produce 
* these volages for 1's and 0's
fset vih 1.0
fset vil 0.0

* Output logic high/low 
fset voh 0.9
fset vol 0.1

fset slope 40e-12
fset tunit 1e-12
fset ndigit 12

* Here we define a mask to help the below check_window command
* We want to have use the check_window command to let the tool check for output correctness only
* at the positive edges of the clock.

* This command doesn't seem to work, need to define clkmask manually in output vec file
*fset mask clkmask clk

* make period 5.0 since alu done after 2 cycles

* Need to modify the <period_time> to be your clock period in the vcd testbench
* <first_time> is the first positive clock edge you want to start checking at
* time unit is ns
* check_window is intentionally disabled: in FineSim it triggers continuous per-timestep comparison
* instead of restricting checks to periodic windows, causing ~100k false errors.
* fix_outputs.py post-processes test.vec to mark output columns x everywhere except at the last
* stable row before each 5 ns check point, so FineSim only strobes at those rows.
*fset vcd2vec check_window 0 0.01 3 5.0 4.9

vinit

* --- ALU Inputs ---
vsignal clk in bin
vsignal rst_n in bin
vsignal scale in bin
vsignal x0r[15:0] in bin
vsignal x0i[15:0] in bin
vsignal x1r[15:0] in bin
vsignal x1i[15:0] in bin
vsignal wr[15:0] in bin
vsignal wi[15:0] in bin

* --- ALU Outputs ---
vsignal X0r0[15:0] out bin
vsignal X0i0[15:0] out bin
vsignal X1r0[15:0] out bin
vsignal X1i0[15:0] out bin

vrun
