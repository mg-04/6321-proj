##################################################
#  Modelsim do file to run simuilation
#  MS 7/2015
##################################################

vlib work 
vmap work work

# include standard cell verilog model
vlog +acc -incr /courses/ee6350/pdk2025/tcbn65gplus/TSMCHOME/digital/Front_End/verilog/tcbn65gplus_140b/tcbn65gplus_pwr.v

# include the testbench file
vlog +acc -incr tb_alu.v 

# include verilog modules
vlog +acc -incr ../../innovus/alu/alu.PG.v 


# run simulation with sdf annotations and check waveforms 
# here we suppress some timing checks in dut level sdf

vsim -voptargs=+acc -t ps -lib work \
-suppress 12088,12090,3262 \
-sdfmax testbench/dut=../../innovus/alu/alu.verilog.sdf \
testbench

do waveformat.do   
run -all
