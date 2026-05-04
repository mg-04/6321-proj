.PHONY: all clean

all: clean test.mod.vec

test.vec: vcd2vec.fscript.sp
	/tools/synopsys/finesim/U-2023.03-SP2-2/bin/fscript vcd2vec.fscript.sp

test.mod.vec: test.vec
	cp test.vec test.mod.vec

clean: 
	rm -rf *.vec backup/*

