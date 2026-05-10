##################################################
#  Modelsim do file to run simuilation
#  MS 7/2015
##################################################

vlib work 
vmap work work

# include standard cell verilog model
vlog +acc -incr /courses/ee6350/pdk2025/tcbn65gplus/TSMCHOME/digital/Front_End/verilog/tcbn65gplus_140b/tcbn65gplus.v

# include the testbench file
vlog +acc -incr tb_alu.v 

# include verilog modules
vlog +acc -incr ../../dc/alu/alu.nl.v 

# run simulation with sdf annotations and check waveforms 

# TODO: remove 
vsim -voptargs=+acc +notimingchecks -t ps -lib work \
-sdftyp /testbench/dut=../../dc/alu/alu.syn.sdf \
testbench

do waveformat.do   
run -all
