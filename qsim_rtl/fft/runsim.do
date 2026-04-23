##################################################
#  Modelsim do file to run simuilation
#  MS 7/2015
##################################################

vlib work 
vmap work work

# Include Netlist and Testbench
vlog +acc -incr ../../rtl/alu/alu.v
vlog +acc -incr ../../memory_compiler/sram05/sram05.v
vlog +acc -incr ../../rtl/sram_wrapper05/sram_wrapper05.v
vlog +acc -incr ../../memory_compiler/sram02/sram02.v
vlog +acc -incr ../../rtl/sram_wrapper02/sram_wrapper02.v
vlog +acc -incr ../../rtl/fft/fft.v 
vlog +acc -incr test_fft.v 

# Run Simulator 
vsim +acc -t ps -lib work testbench 
do waveformat.do   
run -all