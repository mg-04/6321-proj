#########################################
# TCL script for Design Compiler        #
# MS 2015                               #
#########################################

##################################################
# Read design and library
##################################################

# Set the top_level name
set top_level fft

# In this file, libray path and libraries which are used are defined
source -verbose "../common_scripts/common.tcl" 

# Read libraries
set search_path [list \
	"." \
	"/courses/ee6350/pdk2025/tcbn65gplus/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn65gplus_200a" \
	"/tools/synopsys/syn/U-2022.12-SP7/libraries/syn" \
	"../../memory_compiler/sram01/sram01_libs"\
	"../../memory_compiler/sram02/sram02_libs" \
	]
set synthetic_library [list "dw_foundation.sldb"]
set link_library [list \
	"*" \
	"tcbn65gplustc_ccs.db" \
	"dw_foundation.sldb" \
	"sram01_nldm_tt_1p00v_1p00v_25c_syn.db" \
	"sram02_nldm_tt_1p00v_1p00v_25c_syn.db" \
	]
set target_library [list "tcbn65gplustc_ccs.db"]

# Read verilog files
analyze -format verilog "../../rtl/$top_level/$top_level.v"
analyze -format verilog "../../dc/alu/alu.nl.v"
analyze -format verilog "../../dc/sram_wrapper01/sram_wrapper01.nl.v"
analyze -format verilog "../../dc/sram_wrapper02/sram_wrapper02.nl.v"
#analyze -format verilog "../../memory_compiler/sram01/sram01.v"
#analyze -format verilog "../../memory_compiler/sram02/sram02.v"
elaborate $top_level

# List the names of the designs loaded in memory
# Note: This command don't have any functionality for synthesis
#       This is for debugging
list_designs

# Check errors
if { [check_error -v] == 1 } { exit 1 }

# Set the current design
# Note: The active design is called the current design
#       Most commands are specific to the current design
current_design $top_level

# Link the design
# Note: The design must be connected to all the library components and designs if references
#       For each subdesign, a reference and a link must exist between the subdesign and a design or component
#       in the link libraries
link


##################################################
# Define design rule constraints                    
##################################################

# Set maximum fanout of gates
# Note: This command sets the maximum allowable fanout load for the listed input ports
#       The object lists specifies a list of input ports and/or designs on which the max_fanout attribute is to be set
set_max_fanout 4 $top_level
set_max_fanout 4 [all_inputs]

# Set a maximum capacitance for the nets attached to named ports or to all the nets in a design
set_max_capacitance 0.005 [all_inputs]

# Verify the design consistency
# Note: This command reports an error that DC cannot resolve or a warning
check_design


##################################################
# Define design optimization constraints
##################################################

# Set timing environment through another .tcl file
source -verbose "./timing.tcl"

#########################################
# Don't touch synthesized submodules    #
#########################################

set_dont_touch data_mem
set_dont_touch weight_mem
set_dont_touch butterfly_unit

# Set the fix_multiple_port_nets attribute to a specified value on the current design or a list of designs
# Note: '-all' option inserts buffers to the ports
#       '-buffer_constants' option inserts buffers to logic constants instead of duplicating them
set_fix_multiple_port_nets -all -buffer_constants


##################################################
# Optimize the design
##################################################

# Verify the design consistency
check_design

# Set the current design
current_design $top_level

# Link the design
link

# This allows for maximum timing optimization across ALU/Memory interfaces
#set_ungroup [get_designs *]

# Synthesize the design
# Note : This command performs a high-effort compile on the current design for better quality of results (QoR)
compile_ultra

# use compile to not touch internal blocks
# compile


##################################################
# Analyze and resolve design problems
##################################################

# Verify the design consistency
check_design

# Rename modules, signals according to the naming rules
source -verbose "../common_scripts/namingrules.tcl"

# Generate a report file
set rpt_file "${top_level}.dc.rpt"
set maxpaths 20

check_design >> ${rpt_file}

report_area  >> ${rpt_file}
report_power -hier -analysis_effort medium >> ${rpt_file}
report_design >> ${rpt_file}
report_cell >> ${rpt_file}
report_port -verbose >> ${rpt_file}
report_compile_options >> ${rpt_file}
report_constraint -all_violators -verbose >> ${rpt_file}
report_timing -path full -delay max -max_paths $maxpaths -nworst 100 >> ${rpt_file}
report_timing_requirements >> ${rpt_file} 

report_timing -delay max -nworst 1 -max_paths 10000 -path end -nosplit -unique -sort_by slack > ${top_level}.syn.critical_regs
report_timing -delay max -nworst 1 -max_paths 10000 -path full -nosplit -unique -sort_by slack > ${top_level}.syn.critical_regs.full
report_timing -delay max -nworst 1 -max_paths 10000 -path end -nosplit -unique -sort_by slack -to [all_outputs] > ${top_level}.syn.critical_regs.output
report_timing -delay max -nworst 1 -max_paths 10000 -path end -nosplit -unique -sort_by slack -to [all_registers -data_pins] > ${top_level}.syn.critical_regs.regs
report_timing -delay min -nworst 1 -max_paths 10000 -path short -nosplit -unique -sort_by slack > ${top_level}.syn.fast_path


##################################################
# Save the design database 
##################################################

# Generate structural verilog netlist
write -hierarchy -format verilog -output "${top_level}.nl.v"

# Write a Standard Delay Format (SDF) file
# Note : SDF is an IEEE standard for the representation and interpretation of timing data
#        The SDF file includes delays (module path, device, interconnect, and port), timing checks (setup, hold, recovery, skew, width, and period),
#        timing constraints (path and skew), incremental and absolute delays, and so on
write_sdf "${top_level}.syn.sdf"

# Write a SDC file
# Note : SDC is a format used to specify the design intent, including the timing, power and area constraints for a design
write_sdc "${top_level}.syn.sdc" -version 1.7

# Finish synthesis
quit
