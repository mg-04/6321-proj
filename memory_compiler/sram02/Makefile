# --- Variables ---
# Path to the SRAM compiler binary
COMPILER = /tools/misc/EE6321/arm/tsmc/cln65gplus/sram_dp_hdc_svt_rvt_hvt/r0p1/bin/sram_dp_hdc_svt_rvt_hvt

# SRAM Instance Configuration
INST_NAME = sram02
OUT_DIR   = sram02_libs
WORDS     = 1024
BITS      = 32
FREQ      = 1000
MUX       = 8

# Common flags used for all views
FLAGS = -instname $(INST_NAME) -words $(WORDS) -bits $(BITS) -frequency $(FREQ) \
        -mux $(MUX) -drive 6 -write_mask on -write_thru on -wp_size 8 \
        -top_layer m5-m9 -redundancy off -bmux off -ser none -back_biasing off \
        -power_gating off -atf off -cust_comment "First Attempt" \
        -left_bus_delim "[" -right_bus_delim "]" -prefix "" -name_case upper \
        -check_instname on -diodes on \
        -pwr_gnd_rename VDDPE:VDD,VDDCE:VDD,VSSE:VSS

# --- Targets ---

.PHONY: all sram db clean

# Default target: generates all views and the .db file
all: sram db

# Equivalent to run.sh: Generates all SRAM views
sram:
	$(COMPILER) verilog $(FLAGS)
	$(COMPILER) synopsys $(FLAGS)
	$(COMPILER) lvs $(FLAGS)
	$(COMPILER) vclef-fp $(FLAGS)
	$(COMPILER) gds2 $(FLAGS)
	mkdir -p $(OUT_DIR)
	@echo "Moving generated files to $(OUT_DIR)..."
	mv $(INST_NAME)*.lib $(OUT_DIR)/

# Equivalent to gen_db.sh: Converts .lib to .db using Library Compiler
db:
	lc_shell -xg_mode -f lc.command | tee lc.log

# Equivalent to nuke.sh
clean:
	rm -rf *.cdl *.gds2 *.vclef *.lib *.v *.clf lc_output.txt *.log *.db