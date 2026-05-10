.PHONY: all clean

all: clean test.vec

test.vec: vcd2vec.fscript.sp
	/tools/synopsys/finesim/U-2023.03-SP2-2/bin/fscript vcd2vec.fscript.sp

test.mod.vec: test.vec fix_outputs.py
	python3 fix_outputs.py test.vec test.mod.vec

clean: 
	rm -rf *.vec backup/*

