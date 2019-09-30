all: build

build:
	@if [ ! -e work ]; then vlib work; fi
	@vlog -sv +incdir+../../../../rtl/verilog/pkg -f msi_verilog.vc
	@vcom -2008 -f msi_vhdl.vc
	vsim -c -do run.do work.riscv_msi_testbench
