##################################################
#  Modelsim do file to run simuilation
#  MS 7/2015
##################################################

vlib work 
vmap work work

# include standard cell verilog model
vlog +acc -incr /courses/ee6350/pdk2025/tcbn65gplus/TSMCHOME/digital/Front_End/verilog/tcbn65gplus_140b/tcbn65gplus.v

# include the testbench file
vlog +acc -incr tb_fft.v 

# include verilog modules
vlog +acc -incr ../../dc/alu/alu.nl.v 
vlog +acc -incr ../../dc/fft/fft.nl.v 
vlog +acc -incr ../../dc/sram_wrapper01/sram_wrapper01.nl.v 
vlog +acc -incr ../../memory_compiler/sram01/sram01.v 
vlog +acc -incr ../../dc/sram_wrapper02/sram_wrapper02.nl.v 
vlog +acc -incr ../../memory_compiler/sram02/sram02.v 

# run simulation with sdf annotations and check waveforms 

vsim -voptargs=+acc -t ps -lib work \
-sdftyp testbench/dut/butterfly_unit=../../dc/alu/alu.syn.sdf \
-sdftyp testbench/dut/weight_mem=../../dc/sram_wrapper01/sram_wrapper01.syn.sdf \
-sdftyp testbench/dut/data_mem=../../dc/sram_wrapper02/sram_wrapper02.syn.sdf \
testbench

do waveformat.do   
run -all
