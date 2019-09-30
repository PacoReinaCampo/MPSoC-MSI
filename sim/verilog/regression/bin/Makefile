all: build

build:
	@if [ ! -e work ]; then vlib work; fi
	@vlog -sv +incdir+../../../../rtl/verilog/pkg -f msi.vc
	vsim -c -do run.do work.riscv_msi_testbench
