##################################################
# Innovus Script
##################################################


##################################################
# Setup design
##################################################

set design_name alu
source ./config.globals
set_message -no_limit
set_message -id {TECHLIB-1467} -limit 10
setMultiCpuUsage -localCpu max -acquireLicense 8
init_design

##################################################
# Set parameters for the floorplan
##################################################

# Need modification
set std_cell_height 1.8
# core_height should be a multiple of the std_cell_height
# Need to iterate the core width and height to make the density close to 0.7
set core_width 150
set core_height [expr 80*$std_cell_height]

set ring_left_width 1
set ring_right_width 1
set ring_top_width 1
set ring_bottom_width 1
set ring_left_space 0.5
set ring_right_space 0.5
set ring_top_space 0.5
set ring_bottom_space 0.5


######################k############################
# Create the floorplan
##################################################

# Specify the floorplan dimensions by size; or by die, I/O, or core coordinates (Need modification)
floorPlan -s $core_width $core_height 10 10 10 10

# GUI only
redraw
fit

##################################################
# Generate power rails
##################################################

proc connect_std_cells_to_power { } {
    globalNetConnect VDD -type tiehi -inst * -verbose
    globalNetConnect VSS -type tielo -inst * -verbose
    globalNetConnect VDD -type pgpin -pin VDD -inst * -verbose
    globalNetConnect VSS -type pgpin -pin VSS -inst * -verbose
}

connect_std_cells_to_power
applyGlobalNets

addRing -nets {VDD VSS} -type core_rings -layer {top M5 bottom M5 left M6 right M6} -width $ring_top_width \
        -spacing $ring_top_space -center 1 \
	    -extend_corner {lt lb rt rb}

redraw
fit

addStripe -block_ring_top_layer_limit M6 \
	  -block_ring_bottom_layer_limit M6 \
	  -padcore_ring_top_layer_limit M6 \
	  -padcore_ring_bottom_layer_limit M6 \
          -max_same_layer_jog_length 6 \
          -merge_stripes_value 4 \
	  -layer M6 \
          -set_to_set_distance 8 \
          -direction vertical \
          -nets {VDD VSS} \
	  -width 1 \
	  -spacing 0.5 \
	  -area [list 0 0 $core_width $core_height]

sroute -nets {VDD VSS} -allowJogging 0 -allowLayerChange 0 -blockPinTarget boundaryWithPin

##################################################
# Set all the input/output ports
##################################################
 
# Load an I/O assignment file 
loadIoFile "./$design_name.io"

redraw

# Save the flooprlan information to a file (intermediate saving)
saveDesign "$design_name.floorplan.enc"


##################################################
# Place design
##################################################

Puts "####################"
Puts "###"
Puts "### Place Design ..."
Puts "###"
Puts "####################"

#######"

# Defines the process technology value 
setDesignMode -process 65 -flowEffort standard

#set designName ibex_dut
# Control certain aspects of how the software places cells
setPlaceMode -timingdriven true -congEffort high -reorderScan true

# Limit routing layers to leave upper metals for power/clock
setMaxRouteLayer 5 

# Enable high-effort fanout fixing early (from sram_wrapper)
setOptMode -fixFanoutLoad true -effort high -moveInst true -reclaimArea true

placeDesign
#placeDesign -noPrePlaceOpt
setDrawView place
connect_std_cells_to_power

#saveDesign "$design_name.post_placement_no_opt.enc"
#saveNetlist "$design_name.post_placement_no_opt.v" -excludeLeafCell
#write_sdf  "$design_name.post_placement_no_opt.sdf" -nonegchecks
#redraw

#setOptMode -leakagePowerEffort high
setOptMode -yieldEffort none ; # Default is none
setOptMode -effort high ; # man setOptMode and see the effort table
setOptMode -maxDensity 0.95 ; # Default is 0.95 (netlist won't grow above this value)
setOptMode -drcMargin 0.0 ; # Default is 0
#setOptMode -holdTargetSlack 0.0 
setOptMode -holdTargetSlack 0.15
setOptMode -setupTargetSlack 0.0
setOptMode -SimplifyNetlist false ; # When true, simplifies the netlist to decrease congestion, area, and improve runtime
#clearClockDomains
setOptMode -usefulSkew true
#optDesign -preCTS -outDir ${designName}_reports/1_preCTSOpt
#timeDesign -reportOnly -slackReports -outDir ${designName}_reports/1_preCTSOpt
connect_std_cells_to_power
#saveDesign "$design_name.post_placement_opt.enc"
#saveNetlist "$design_name.post_placement_opt.v" -includePowerGround
redraw

# Place stanard cells based on the global settings for placement, RC extraction, and timing analysis
# Check FIXED and PLACED cells for violations, add violation markers to the design display area
checkPlace

# Build the static timing model of the design
buildTimingGraph


##################################################
# Do preCTS optimization
##################################################

Puts "###########################"
Puts "###"
Puts "### PreCTS Optimization ..."
Puts "###"
Puts "###########################"

#set_dont_touch clkloc_inst

# Perform timing optimization before or after the clock tree is built, or after routing and generate timing reports
# Notes: '-preCTS' option performs timing optimization on the placed design, before the clock tree is built
optDesign -preCTS

# Save design
#redraw
#saveDesign "$design_name.placed.enc"


####################################################
### Do clock tree synthesis
####################################################

Puts "############################"
Puts "###"
Puts "### Clock Tree Synthesis ..."
Puts "###"
Puts "############################"

# Set global analysis modes for timing analysis
# Notes: '-cppr' option removes pessimism from clock paths
#        '-analysisType bcwc' option checks the design for two extreme conditions
#setAnalysisMode -cppr both
update_constraint_mode -name typical_constraint -sdc_file "../../dc/$design_name/$design_name.syn.mod.sdc"

set_analysis_view -setup {typical} -hold {typical}

# Define route types
create_route_type -name leaf_rule -top_preferred_layer M5 -bottom_preferred_layer M4
create_route_type -name trunk_rule -top_preferred_layer M5 -bottom_preferred_layer M4
create_route_type -name top_rule -top_preferred_layer M5 -bottom_preferred_layer M4
# Specify route types
set_ccopt_property -net_type leaf route_type leaf_rule
set_ccopt_property -net_type trunk route_type trunk_rule
set_ccopt_property -net_type top route_type top_rule
set_ccopt_property routing_top_min_fanout 10000

######################################################################################

# Specify the buffer and inverter cells for CTS 
set_ccopt_property inverter_cells [list CKND1 CKND12 CKND16 CKND2 CKND20 CKND24 CKND3 CKND4 CKND6 CKND8]
set_ccopt_property buffer_cells [list CKBD1 CKBD12 CKBD16 CKBD2 CKBD20 CKBD24 CKBD3 CKBD4 CKBD6 CKBD8]

# Use inverters in pfreference to buffers
set_ccopt_property use_inverters true
# Configure the maximum transition target
#set_ccopt_property target_max_trans 20ps
# Configure a skew target for CCOpt-CTS
set_ccopt_property target_skew 15ps


# From the .ccopt.skew.rpt
# no need to include, since apr as a whole

# Create a clock tree network with associated skew groups and other CTS configuration settings
create_ccopt_clock_tree_spec -file ccopt_clock_tree.spec
source "./ccopt_clock_tree.spec"

# Perform clock concurrent optimization (CCOpt) on the current loaded design in Innovus
# CCOpt optimizes both the clock tree and the datapath to meet global timing constraints
# Paul added: -cts 
ccopt_design -cts

# enable cppr and time checking
setAnalysisMode -cppr both
timeDesign -postCTS
optDesign -postCTS
timeDesign -postCTS -hold
optDesign -postCTS -hold

# Generate skew and clock tree report
report_ccopt_skew_groups -file "$design_name.ccopt.skew.rpt"
report_ccopt_clock_trees -file "$design_name.ccopt.clk_tree.rpt"

saveDesign "$design_name.clock.enc"
savePlace "$design_name.place"


##################################################
# Route signals
##################################################

# Unfix the clock nets to avoid routing problems
 changeUseClockNetStatus -noFixedNetWires

##################################################

Puts "###########################"
Puts "###"
Puts "### Route Signals ..."
Puts "###"
Puts "###########################"

############## Route all other nets ##############

setNanoRouteMode -quiet -routeSelectedNetOnly false
setNanoRouteMode -quiet -routeWithTimingDriven true
setNanoRouteMode -quiet -routeTdrEffort 10
setNanoRouteMode -quiet -drouteFixAntenna true
setNanoRouteMode -quiet -routeWithSiDriven true
setNanoRouteMode -quiet -routeSiLengthLimit 200
setNanoRouteMode -quiet -routeSiEffort high
setNanoRouteMode -quiet -routeWithViaInPin false
setNanoRouteMode -quiet -routeWithViaOnlyForStandardCellPin false
setNanoRouteMode -quiet -drouteUseMultiCutViaEffort high
setNanoRouteMode -routeTopRoutingLayer 5
setNanoRouteMode -routeBottomRoutingLayer 1
setNanoRouteMode -drouteElapsedTimeLimit 0
setNanoRouteMode -drouteAutoStop false
globalDetailRoute
redraw
##################################################


##################################################
# Extract and optimize
##################################################

Puts "######################################"
Puts "###"
Puts "### RC Extraction and Optimization ..."
Puts "###"
Puts "######################################"

# Set the native RC extraction mode
# Notes: This command should be used before using the extractRC command
setExtractRCMode -engine postRoute -effortLevel low -coupled true

# Extract resistance and capacitance for the interconnects and store the results in an RC database
extractRC

# Set global analysis modes for timing analysis
# Notes: '-analysisType onChipVaration' option calculates the delay for one path based on maximum operation
#        condition while calculating the delay for another path based on minimum operating condition
#        for setup or hold checks
setAnalysisMode -analysisType onChipVariation -cppr both

# Set global parameters for timing optimization
setOptMode -yieldEffort none
setOptMode -effort high
setOptMode -drcMargin 0.0
setOptMode -maxDensity 0.95
setOptMode -holdTargetSlack 0.1 -setupTargetSlack 0.0
setOptMode -holdFixingEffort high
setOptMode -simplifyNetlist false
setOptMode -usefulSkew true
setOptMode -moveInst true
setOptMode -reclaimArea true
setOptMode -fixDRC true
setOptMode -fixCap true
setOptMode -fixTran true     ;# Specifically for max_transition (CRITICAL)
setOptMode -fixFanoutLoad true
setOptMode -effort high

# Perform timing optimization before or after the clock tree is built, or after routing
# Notes: '-hold' option corrects hold violations
#        '-postRoute' option performs timing optimization on a design whose routing is complete
optDesign -postRoute -drv
optDesign -postRoute -setup
optDesign -postRoute -hold -incremental

# Connect all new cells to VDD/GND
globalNetConnect VDD -type pgpin -pin {VDD} -override
globalNetConnect VSS -type pgpin -pin {VSS} -override
globalNetConnect VDD -type tiehi
globalNetConnect VSS -type tielo
applyGlobalNets

# Save design 
## Save design 
saveDesign "$design_name.routed.enc"
#saveNetlist "$design_name.post_extraction_2.v" -excludeLeafCell
#write_sdf  "$design_name.post_extraction_2.sdf" -nonegchecks


## Connect all new cells to VDD/GND
connect_std_cells_to_power
applyGlobalNets

## Clear DRC
clearDrc
verify_drc
verifyGeometry -allowDiffCellViols
verifyConnectivity -type regular -error 1000 -warning 50



##################################################
# Add decap or fillers
##################################################

Puts "############################"
Puts "###"
Puts "### Add Decap or Fillers ..."
Puts "###"
Puts "############################"

# Check width, spacing, and internal geometry of objects and the wiring between them
# Create and save violation markers in the design database
verify_drc

# Add filler cells 
# Notes: '-cell' option specifies the list of filler cells to add
# addFiller -cell FILL16TS FILL1TS FILL2TS FILL32TS FILL4TS FILL64TS FILL8TS -prefix IBM13RFLPVT_FILLER
addFiller -cell DCAP64 DCAP32 DCAP16 DCAP8 DCAP4 FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1 -prefix FILLER
verifyGeometry
verify_drc


##################################################
# Verify the design
##################################################

Puts "##############"
Puts "###"
Puts "### Verify ..."
Puts "###"
Puts "##############"

# Clear all design rule checking (DRC) markers in your design
clearDrc
verify_drc

# Detect conditions such as opens, unconnected wires, unconnected pins, loops, partial routing, and unrouted nets
# Generate violation markers in the design window
verifyConnectivity -type all

# Verify process antenna effect (PAE) and maximum floating area violations
verifyProcessAntenna

##################################################
# Produce outputs
##################################################

Puts "#######################"
Puts "###"
Puts "### Produce Outputs ..."
Puts "###"
Puts "#######################"

# Report
report_power -leakage -cap -nworst -pg_pin -outfile "$design_name.power.rpt"

# Generate hierarchical design abstract (LEF) information for the current routed block-level design
#write_lef_abstract "$design_name.lef" -5.7 -PgpinLayers {5 6} -specifyTopLayer 6 -stripePin -extractBlockPGPinLayers {5 6}
write_lef_abstract "$design_name.lef" -5.7 -PgpinLayers 6 -specifyTopLayer 6 -stripePin -extractBlockPGPinLayers 6

# Write the specified information to a DEF file
defOut -floorplan -netlist -routing "$design_name.final.def"

# Create a GDSII file of the current database
# Notes: '-mapFile' option specifies the file used for layer mapping
#        '-libName' option specifies the library to convert to GDSII Stream format
streamOut "$design_name.gds" -mapFile "../layermap/tsmc65_6350_spring24.layermap" -libName tcbn65gplus -structureName $design_name -units 1000 -mode ALL 

# Write a netlist file of the design
# Notes: '-phys' option writes out physical cell instances, and inserts power and ground nets in the netlist
saveNetlist -phys -excludeLeafCell -excludeCellInst "FILL1 FILL2 FILL4 FILL8 FILL16 FILL32 FILL64 FILL1_LL FILL_NW_FA_LL FILL_NW_HH FILL_NW_LL" "$design_name.phy.v"
saveNetlist "$design_name.nophy.v"
saveNetlist -includePhysicalCell "DCAP64 DCAP32 DCAP16 DCAP8 DCAP4" -includePowerGround -excludeLeafCell -excludeCellInst "FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1" "$design_name.PG.v"

# Extract RC information
extractRC -outfile "$design_name.cap"
rcOut -spef "$design_name.spef"

# Write delays to a Standard Delay Format (SDF) file
write_sdf -version 2.1 "$design_name.sdf"
write_sdf -version 2.1 -target_application verilog "$design_name.verilog.sdf"

# Report hold/setup violation
setAnalysisMode -checkType hold -useDetailRC true
report_timing -check_type hold -nworst 5 > "$design_name.hold.rpt"
setAnalysisMode -checkType setup -useDetailRC true
report_timing -check_type setup -nworst 5 > "$design_name.setup.rpt"
reportCapViolation -outfile final_cap.tarpt

# Run DRC and connection checks
verifyGeometry
verifyConnectivity -type all

# Report statistics for the entire design
summaryReport -outfile "$design_name.summary.rpt"

# Generate a file containing a list of nets which have critical slack of the currently specified timing analysis mode
reportCritNet -outfile "$design_name.critnet.rpt"

do_extract_model "$design_name.lib" -view typical

puts "########################################"
puts "#                                      #"
puts "# And finally ...                      #"
puts "#                                      #"
puts "# Encounter script finished            #"
puts "#                                      #"
puts "########################################"

exit
