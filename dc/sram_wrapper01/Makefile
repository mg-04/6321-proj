# Variables
MODULE_NAME = sram_wrapper01
# Calling the python binary directly from the env to avoid 'source activate' subshell issues
PYTHON_BIN  = /courses/ee6350/pdk2025/miniconda3/bin/python

.PHONY: all synth clean

# Default target
all: synth

# Synthesis and Post-Processing
synth:
	@echo "Starting Synthesis for $(MODULE_NAME)..."
	dc_shell -f module.tcl | tee log
	@echo "--> Producing $(MODULE_NAME).nl.PG.v"
	$(PYTHON_BIN) add_pg.py $(MODULE_NAME)
	@echo "--> Commenting out set_ideal_network in $(MODULE_NAME).syn.mod.sdc"
	$(PYTHON_BIN) proc_sdc.py $(MODULE_NAME)

# Cleanup
clean:
	@echo "Cleaning up intermediate files..."
	rm -rf *.sdf *.rpt *log* *.sdc *.svf alib-52 *.nl.v \
	       *.syn.fast_path *.syn.critical_regs* *.csd *.nl.PG.v *.mr*