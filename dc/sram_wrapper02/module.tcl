#########################################
# TSMC 65nm Synthesis                   #
# TCL script for Design Compiler        #
# 2024 Paul Huang                       #
#########################################

#########################################
# READ Design and Library               #
#########################################

# Set top level module name
set top_level sram_wrapper02

# Read libraries
set search_path [list \
    "." \
    "/courses/ee6350/pdk2025/tcbn65gplus/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn65gplus_200a" \
    "/tools/synopsys/syn/U-2022.12-SP7/libraries/syn" \
    "../../memory_compiler/sram02/sram02_libs" \
]
set synthetic_library [list "dw_foundation.sldb"]
set link_library [list "*" "tcbn65gplustc_ccs.db" "dw_foundation.sldb" "sram02_nldm_tt_1p00v_1p00v_25c_syn.db"]
set target_library [list "tcbn65gplustc_ccs.db"]

# Read verilog files and elaborate
analyze -format verilog "../../rtl/$top_level/$top_level.v"

elaborate $top_level

# List the names of the designs
list_designs

# Check error
if { [check_error -v] == 1 } { exit 1 }

# Link the design
link
check_design

# Set current design
current_design $top_level
check_design

#########################################
# Design Constraints                    #
#########################################

set_max_capacitance 0.005 [all_inputs]
set_max_fanout 4 [all_inputs]
set_max_fanout 4 $top_level

set_fix_multiple_port_nets -all -buffer_constants

check_design

# Timing constraints
source -verbose "./timing.tcl"

#########################################
# Compile                               #
#########################################

current_design $top_level
link

compile

#########################################
# Write outputs                         #
#########################################
source -verbose "../common_scripts/namingrules.tcl"
write -hierarchy -format verilog -output "${top_level}.nl.v"
write_sdf -context verilog "${top_level}.temp.sdf"
write_sdf "${top_level}.syn.sdf"
write_sdc "${top_level}.syn.sdc" -version 2.1

# Generate report file
set maxpaths 20
set rpt_file "${top_level}.dc.rpt"
check_design > $rpt_file
report_area  >> ${rpt_file}
report_power -verbose -hier -analysis_effort medium >> ${rpt_file}
report_design >> ${rpt_file}
report_cell >> ${rpt_file}
report_port -verbose >> ${rpt_file}
report_compile_options >> ${rpt_file}
report_constraint -all_violators -verbose >> ${rpt_file}
report_timing -path full -delay max -max_paths $maxpaths -nworst 100 >> ${rpt_file}

report_timing -delay max -nworst 1 -max_paths 10000 -path end -nosplit -unique -sort_by slack > ${top_level}.syn.critical_regs
report_timing -delay max -nworst 1 -max_paths 10000 -path full -nosplit -unique -sort_by slack > ${top_level}.syn.critical_regs.full
report_timing -delay max -nworst 1 -max_paths 10000 -path end -nosplit -unique -sort_by slack -to [all_outputs] > ${top_level}.syn.critical_regs.output
report_timing -delay max -nworst 1 -max_paths 10000 -path end -nosplit -unique -sort_by slack -to [all_registers -data_pins] > ${top_level}.syn.critical_regs.regs
report_timing -delay min -nworst 1 -max_paths 10000 -path short -nosplit -unique -sort_by slack > ${top_level}.syn.fast_path

quit
