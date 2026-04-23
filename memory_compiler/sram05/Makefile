# --- Variables ---
# Path to the ROM compiler binary
COMPILER = /tools/misc/EE6321/arm/tsmc/cln65gplus/rom_via_hde_hvt_rvt_hvt/r0p0-00eac0/bin/rom_via_hde_hvt_rvt_hvt

# ROM Instance Configuration
INST_NAME = sram05
OUT_DIR   = sram05_libs
WORDS     = 512
BITS      = 32
FREQ      = 1000
MUX       = 8
DRIVE     = 6
CODE_FILE = code.hex

# Common flags used for all ROM views
FLAGS = -instname $(INST_NAME) -words $(WORDS) -bits $(BITS) -frequency $(FREQ) \
        -mux $(MUX) -drive $(DRIVE) -top_layer m5-m9 -bmux off -back_biasing off \
        -power_gating off -atf off -cust_comment "First Attempt" \
        -left_bus_delim "[" -right_bus_delim "]" -prefix "" -name_case upper \
        -check_instname on -diodes on \
        -pwr_gnd_rename VDDE:VDD,VSSE:VSS \
        -code_file $(CODE_FILE)

# --- Targets ---

.PHONY: all rom db clean

# Default target: generates all views and the .db file
all: clean rom db

# Generates all ROM views (Verilog, Synopsys, LVS, CLEF, GDS)
rom:
	$(COMPILER) verilog $(FLAGS)
	$(COMPILER) synopsys $(FLAGS)
	$(COMPILER) lvs $(FLAGS)
	$(COMPILER) lef-fp $(FLAGS)
	$(COMPILER) gds2 $(FLAGS)
	mkdir -p $(OUT_DIR)
	@echo "Moving generated files to $(OUT_DIR)..."
	mv $(INST_NAME)*.lib $(OUT_DIR)/

# Converts .lib to .db using Synopsys Library Compiler
db:
	lc_shell -xg_mode -f lc.command | tee lc.log

# Cleanup generated files
clean:
	rm -rf *.cdl *.gds2 *.vclef *.lib *.v *.clf lc_output.txt *.log *.db
	rm -rf $(INST_NAME)_libs/*