all: build simulate

build:
	verilator -Wno-lint --cc -f system.vc --top-module peripheral_msi_testbench

simulate:

clean:
	rm -rf obj_dir
