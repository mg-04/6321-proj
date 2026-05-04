* Convert vcd file to vec file 
load vcd ../../../qsim_apr/tb_fft/fft_tb.vcd
open ./test.vec

* These commands make the vector file's io to directly print the signal names 
* without the prefix scope as set in fset scope
fset scope testbench.dut
fset vcd2vec ascope

* First time point to start vector stimuli, e.g., could be positive clock edge
*fset start 5.132e-9
* This is set to equal the clock period in the vcd testbench
*fset step 10e-9

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

* Need to modify the <period_time> to be your clock period in the vcd testbench
* <first_time> is the first positive clock edge you want to start checking at
* time unit is ns
* check_window              <begin_offset>  <end_offset>    <steady>    <period_time>   <first_time>    <mask>
*fset vcd2vec check_window         0            40            1             10             5.132        clkmask 

vinit
vsignal clk in bin
vsignal rst in bin
vsignal start in bin
vsignal mode[1:0] in bin
vsignal mux_addr[9:0] in bin
vsignal din1[31:0] in bin
vsignal din2[31:0] in bin
vsignal scale_mask[9:0] in bin
vsignal done out bin
vsignal dout1[31:0] out bin
vsignal dout2[31:0] out bin

vrun
