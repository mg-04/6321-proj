**** Include library
.include "../common_scripts/lib_tsmc65_gp.l"
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
.option finesim_vdd=1.2



**** Define custom parameters
* Supply voltage VDD volts
.param supply0=1000e-3
* Simulation time
.param sim_time=102e-9
* apr simulation ends at 282 817 500 ps

**** Measure and probe
.probe v(*)

**** Simulation setup
.tran 20e-12 sim_time

**** Netlist
.include "../../innovus/alu/alu.sp"

**** Instantiate ('X' followed by module name represents instance name, ending with module name)
Xalu 
+ clk rst_n scale
+ x0r[15] x0r[14] x0r[13] x0r[12] x0r[11] x0r[10] x0r[9] x0r[8] 
+ x0r[7] x0r[6] x0r[5] x0r[4] x0r[3] x0r[2] x0r[1] x0r[0]
+ x0i[15] x0i[14] x0i[13] x0i[12] x0i[11] x0i[10] x0i[9] x0i[8] 
+ x0i[7] x0i[6] x0i[5] x0i[4] x0i[3] x0i[2] x0i[1] x0i[0]
+ x1r[15] x1r[14] x1r[13] x1r[12] x1r[11] x1r[10] x1r[9] x1r[8] 
+ x1r[7] x1r[6] x1r[5] x1r[4] x1r[3] x1r[2] x1r[1] x1r[0]
+ x1i[15] x1i[14] x1i[13] x1i[12] x1i[11] x1i[10] x1i[9] x1i[8] 
+ x1i[7] x1i[6] x1i[5] x1i[4] x1i[3] x1i[2] x1i[1] x1i[0]
+ wr[15] wr[14] wr[13] wr[12] wr[11] wr[10] wr[9] wr[8] 
+ wr[7] wr[6] wr[5] wr[4] wr[3] wr[2] wr[1] wr[0]
+ wi[15] wi[14] wi[13] wi[12] wi[11] wi[10] wi[9] wi[8] 
+ wi[7] wi[6] wi[5] wi[4] wi[3] wi[2] wi[1] wi[0]
+ X0r0[15] X0r0[14] X0r0[13] X0r0[12] X0r0[11] X0r0[10] X0r0[9] X0r0[8] 
+ X0r0[7] X0r0[6] X0r0[5] X0r0[4] X0r0[3] X0r0[2] X0r0[1] X0r0[0]
+ X0i0[15] X0i0[14] X0i0[13] X0i0[12] X0i0[11] X0i0[10] X0i0[9] X0i0[8] 
+ X0i0[7] X0i0[6] X0i0[5] X0i0[4] X0i0[3] X0i0[2] X0i0[1] X0i0[0]
+ X1r0[15] X1r0[14] X1r0[13] X1r0[12] X1r0[11] X1r0[10] X1r0[9] X1r0[8] 
+ X1r0[7] X1r0[6] X1r0[5] X1r0[4] X1r0[3] X1r0[2] X1r0[1] X1r0[0]
+ X1i0[15] X1i0[14] X1i0[13] X1i0[12] X1i0[11] X1i0[10] X1i0[9] X1i0[8] 
+ X1i0[7] X1i0[6] X1i0[5] X1i0[4] X1i0[3] X1i0[2] X1i0[1] X1i0[0]
+ VDD VSS
+ alu

**** Power supplies
* Here for VDD use a pwl source to ramp up from 0 to VDD at beginning of simulation
vvdd VDD 0 pwl 0 0 1e-9 0 2e-9 supply0
vvss VSS 0 dc=0

.measure tran my_real_power avg P(vvdd) from=10ns to=100ns

**** Provide stimuli through vec file
.vec "./vec_files/test.vec"

.end
