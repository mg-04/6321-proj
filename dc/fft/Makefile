#################################################################
# Makefile for VLSI Synthesis Flow
# Translating shell script for: $(MODULE_NAME)
#################################################################

MODULE_NAME = fft
PYTHON_ENV  = /courses/ee6350/pdk2025/miniconda3/bin/activate
PYTHON_EXEC = source $(PYTHON_ENV) && python

.PHONY: all clean synthesis pg sdc

all: clean synthesis pg sdc

# Synthesis
# This runs dc_shell and produces the netlist and log
$(MODULE_NAME).nl.v $(MODULE_NAME).syn.sdc: $(MODULE_NAME).tcl
	@echo "--> Running Design Compiler for $(MODULE_NAME)..."
	dc_shell -64 -f $(MODULE_NAME).tcl | tee $(MODULE_NAME).log

# add power and ground
$(MODULE_NAME).nl.PG.v: $(MODULE_NAME).nl.v add_pg.py
	@echo "--> Producing $(MODULE_NAME).nl.PG.v"
	$(PYTHON_EXEC) add_pg.py $(MODULE_NAME)

# Process SDC
$(MODULE_NAME).syn.mod.sdc: $(MODULE_NAME).syn.sdc proc_sdc.py $(MODULE_NAME).nl.PG.v
	@echo "--> Commenting out set_ideal_network in $(MODULE_NAME).syn.mod.sdc"
	$(PYTHON_EXEC) proc_sdc.py $(MODULE_NAME)

synthesis: $(MODULE_NAME).nl.v
pg: $(MODULE_NAME).nl.PG.v
sdc: $(MODULE_NAME).syn.mod.sdc

clean:
	rm -rf alib-52
	rm -rf *.log
	rm -rf *.svf
	rm -rf *.nl.v
	rm -rf *.rpt
	rm -rf *.syn*
	rm -rf .cadence
	rm -rf *.pvl
	rm -rf *.nl.PG.v
	rm -rf *.mr
	rm -rf *.txt