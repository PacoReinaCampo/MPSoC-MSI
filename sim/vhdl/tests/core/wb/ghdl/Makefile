all: build simulate

build:
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/pkg/mpsoc_msi_wb_pkg.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/arbiter/mpsoc_msi_arbiter.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/cdc/mpsoc_msi_wb_cc561.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/cdc/mpsoc_msi_wb_cdc.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/cdc/mpsoc_msi_wb_sync2_pgen.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/core/mpsoc_msi_wb_arbiter.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/core/mpsoc_msi_wb_data_resize.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/core/mpsoc_msi_wb_interface.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/core/mpsoc_msi_wb_mux.vhd
	ghdl -a --std=08 ../../../../../../bench/vhdl/tests/core/wb/mpsoc_msi_testbench.vhd

simulate:
	ghdl -m --std=08 mpsoc_msi_testbench
	ghdl -r --std=08 mpsoc_msi_testbench --ieee-asserts=disable-at-0 --disp-tree=inst > mpsoc_msi_testbench.tree

clean:
	rm -f *.cf *.tree
