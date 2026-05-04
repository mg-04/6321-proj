.PHONY: all hspice clean

hspice: base.sp
	hspice -i base.sp -o base.log -mt 16 -hpp

#### Run finesim
# finesim mode: spicehd, spicemd, spicexd, prohd, promd, and proxd
#/tools/synopsys/finesim/U-2023.03-SP2-2/bin/finesim base.sp -mode promd -mt 16


clean:
	rm -rf logFile *.cap *.elog *.mc0 *.err0 *.veclog *.st* *.tr* *.ic* *.lis *.mt* *.pa* *.su* *.dsn *.meas0 *.ulog *.op0* *.fsdb *.log*
	rm -rf tmp_*
	rm -rf .finesim.cmd.history
