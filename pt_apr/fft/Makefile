all: clean run

run:
	pt_shell -file pt.tcl | tee pt.log

clean:
	rm -rf *.log
	rm -rf *.rpt
	rm -rf *.sdf
	rm -rf *.fsdb	
	
.PHONY: all clean run