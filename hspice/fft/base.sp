**** Include library
.include "../common_scripts/lib_tsmc65_gp.l"
.include "../../memory_compiler/sram02/sram02.cdl"
.include "../../memory_compiler/sram05/sram05.cdl"
.include "/tools/misc/EE6321/arm/tsmc/cln65gplus/sram_dp_hdc_svt_rvt_hvt/r0p1/lib/prims.spc"


* General options
.option POST=1          $ Output format is binary
.option PROBE=1
.option MEASDGT=6
.option NUMDGT=6
.option DCSTEP=1
.option INGOLD=2
.option MEASOUT=1
.option PSF=1           $ Comment out if you want to use the CSCOPE
.option ARTIST=1
.option CAPTAB
.option REDEFSUB=1
.option redefmodel=1

* Spice accuracy options
.option METHOD=GEAR     $ Numerical integration method is used for a transient analysis
.option RELTOL=1e-6     $ Default: 1e-3
.option RUNLVL=6        $ Default: 3
.option GMINDC=1e-24
.option GMIN=1e-24
.option PIVTOL=1e-25



**** Define custom parameters
* Supply voltage VDD volts
.param supply0=1000e-3
* Simulation time
.param sim_time=28282e-9
* apr simulation ends at 282 817 500 ps

**** Measure and probe
.probe v(*)

**** Simulation setup
.tran 1e-9 sim_time

**** Netlist
.include "../../innovus/fft/fft.sp"

**** Instantiate ('X' followed by module name represents instance name, ending with module name)
Xfft 
+ clk rst start 
+ mode[1] mode[0]
+ mux_addr[9] mux_addr[8] mux_addr[7] mux_addr[6] mux_addr[5] 
+ mux_addr[4] mux_addr[3] mux_addr[2] mux_addr[1] mux_addr[0]
+ din1[31] din1[30] din1[29] din1[28] din1[27] din1[26] din1[25] din1[24] 
+ din1[23] din1[22] din1[21] din1[20] din1[19] din1[18] din1[17] din1[16] 
+ din1[15] din1[14] din1[13] din1[12] din1[11] din1[10] din1[9] din1[8] 
+ din1[7] din1[6] din1[5] din1[4] din1[3] din1[2] din1[1] din1[0]
+ din2[31] din2[30] din2[29] din2[28] din2[27] din2[26] din2[25] din2[24] 
+ din2[23] din2[22] din2[21] din2[20] din2[19] din2[18] din2[17] din2[16] 
+ din2[15] din2[14] din2[13] din2[12] din2[11] din2[10] din2[9] din2[8] 
+ din2[7] din2[6] din2[5] din2[4] din2[3] din2[2] din2[1] din2[0]
+ scale_mask[9] scale_mask[8] scale_mask[7] scale_mask[6] scale_mask[5] 
+ scale_mask[4] scale_mask[3] scale_mask[2] scale_mask[1] scale_mask[0]
+ done
+ dout1[31] dout1[30] dout1[29] dout1[28] dout1[27] dout1[26] dout1[25] dout1[24] 
+ dout1[23] dout1[22] dout1[21] dout1[20] dout1[19] dout1[18] dout1[17] dout1[16] 
+ dout1[15] dout1[14] dout1[13] dout1[12] dout1[11] dout1[10] dout1[9] dout1[8] 
+ dout1[7] dout1[6] dout1[5] dout1[4] dout1[3] dout1[2] dout1[1] dout1[0]
+ dout2[31] dout2[30] dout2[29] dout2[28] dout2[27] dout2[26] dout2[25] dout2[24] 
+ dout2[23] dout2[22] dout2[21] dout2[20] dout2[19] dout2[18] dout2[17] dout2[16] 
+ dout2[15] dout2[14] dout2[13] dout2[12] dout2[11] dout2[10] dout2[9] dout2[8] 
+ dout2[7] dout2[6] dout2[5] dout2[4] dout2[3] dout2[2] dout2[1] dout2[0]
+ VDD VSS
+ fft

**** Power supplies
* Here for VDD use a pwl source to ramp up from 0 to VDD at beginning of simulation
vvdd VDD 0 pwl 0 0 1e-9 0 1.1e-9 supply0
vvss VSS 0 dc=0

**** Provide stimuli through vec file
.vec "./vec_files/test.mod.vec"

.end
