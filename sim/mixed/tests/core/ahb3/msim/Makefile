all: build simulate

build:
	if [ ! -e work ]; then vlib work; fi
	vlog -sv  -f system.verilog.vc
	vcom -2008 -f system.vhdl.vc

simulate:
	vsim -c -do run.do work.peripheral_msi_testbench

clean:
	rm -rf work transcript
