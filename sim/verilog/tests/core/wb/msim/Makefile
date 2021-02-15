all: build simulate

build:
	if [ ! -e work ]; then vlib work; fi
	vlog -sv -f system.vc

simulate:
	vsim -c -do run.do work.wb_msi_tb

clean:
	rm -rf work transcript
