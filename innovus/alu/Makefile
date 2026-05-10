# Design Variables
FN = alu
TCL_SCRIPT = alu.tcl

# Paths
PDK_SPI = /courses/ee6350/pdk2025/tcbn65gplus/TSMCHOME/digital/Back_End/spice/tcbn65gplus_200a/tcbn65gplus_200a.spi
REF_DIR = /courses/ee6350/proj_2025Spring/ref/innovus

# Default target: Run APR then make the CDL
all: clean apr cdl

apr:
	@echo "--- Starting Innovus APR Flow ---"
	innovus -init $(TCL_SCRIPT)

cdl:
	@echo "--- Converting Verilog to CDL ---"
	v2lvs -i -t $(FN) \
		-v $(FN).PG.v \
		-o $(FN).cdl \
		-s $(PDK_SPI) \
		-lsr $(PDK_SPI) \
		2>&1 | tee cdl.log
	cp $(FN).cdl $(FN).sp
	@echo "--- CDL and SPICE files generated ---"

clean:
	@echo "--- Cleaning up project directory ---"
	rm -rf innovus* *enc*
	rm -rf ccopt_clock_tree.spec final_cap.tarpt
	rm -rf *.lef *.rpt* *.def* *.gds* *.v *.place *.sdc *.sdf *.spef *.cdl *.sp *.log *.ob *.typical *.latchInferredMCP *.lib *.csd
	rm -rf timingReports summaryReport .cadence
	rm -f  netlist/TIE_temp.v sdc/ibex_dut.sdc *.anls* .timing* *.log* *.cmd .*.cmd


.PHONY: all apr cdl clean


