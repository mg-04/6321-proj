#################################################
# PrimeTime script for static timing analysis   #
# MS 7/2015                                     #
#################################################

# Display long reports one page at a time
set sh_enable_page_mode true

# Enable or Disable PrimePower, which provides power analysis
set power_enable_analysis true


##################################################
# Set files and paths
##################################################

# Set the top_level name
set top_level fft

# Set library paths
set search_path [list \
    "." \
    "/courses/ee6350/pdk2025/tcbn65gplus/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn65gplus_200a" \
    "/home/cad/installs/synopsys/syn/O-2018.06-SP5-1/libraries/syn" \
    "../../memory_compiler/sram05/sram05_libs"\
    "../../memory_compiler/sram02/sram02_libs"\
]

# Specify a list of libraries, design files, and library files used during linking
set link_path [list "*" "tcbn65gplustc_ccs.db" \
	"sram05_nldm_tt_1p00v_1p00v_25c_syn.db" \
	"sram02_nldm_tt_1p00v_1p00v_25c_syn.db" \
]

# Read design or library files
read_db [list "tcbn65gplustc_ccs.db"]

# Read verilog files
set svr_enable_vpp true
read_verilog "../../dc/$top_level/$top_level.nl.v"
#read_verilog "../../dc/alu/alu.nl.v"
#read_verilog "../../dc/sram_wrapper01/sram_wrapper01.nl.v"
#read_verilog "../../memory_compiler/sram01/sram01.v"
#read_verilog "../../dc/sram_wrapper02/sram_wrapper02.nl.v"
#read_verilog "../../memory_compiler/sram02/sram02.v"

# Resolve references in a design
# Note: It resolves all references between different modules in the hierarchy
#       and builds an internal representation of the design for timing analysis
link_design $top_level

##################################################
# Define timing constraints
##################################################

# Timing constraints
source ./timing.tcl

##################################################
# Run PrimeTime 
##################################################

# Generate a report file
set timing_rpt  "${top_level}.timing.rpt"
set power_rpt   "${top_level}.power.rpt"
set constraint_rpt "${top_level}.constraints.rpt"
set design_rpt   "${top_level}.design.rpt"
check_timing

report_design >> ${design_rpt}
report_reference >> ${design_rpt}
report_constraint >> ${constraint_rpt}
report_constraint -all_violators -significant_digits 4 >> ${constraint_rpt}
report_timing -significant_digits 4 -delay_type min_max -nworst 120 >> ${timing_rpt}
report_timing -significant_digits 4 -delay_type min -nworst 120 -slack_greater_than 0 >> ${timing_rpt}
report_timing -significant_digits 4 -delay_type max -nworst 5 -slack_greater_than 0 >> ${timing_rpt}

# Do power analysis # -time {5125000 7655000}
set power_analysis_mode "time_based"
read_vcd "../../qsim_dc/tb_fft/fft_tb.vcd" -time {7583 57270} -strip_path "testbench/dut"

update_power
report_switching_activity >> ${power_rpt}
report_switching_activity -list_not_annotated >> ${power_rpt}
report_power >> ${power_rpt}
report_power -hierarchy >> ${power_rpt}

write_sdf -context verilog "./${top_level}.pt.sdf"

#Finish PrimeTime
quit
