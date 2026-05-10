HSPICE_DIR  = hspice_run
FINESIM_DIR = finesim_run
TOP_SP      = $(CURDIR)/base.sp

.PHONY: all hspice finesim clean

all: clean finesim

hspice:
	mkdir -p $(HSPICE_DIR)
	cd $(HSPICE_DIR) && hspice -i $(TOP_SP) -o base.log -mt 16 -hpp

finesim:
	mkdir -p $(FINESIM_DIR)
	cd $(FINESIM_DIR) && finesim $(TOP_SP) -mode promd -mt 16 -o base

clean:
	rm -rf $(HSPICE_DIR) $(FINESIM_DIR)
	rm -rf logFile tmp_* .finesim.cmd.history