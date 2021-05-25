all: build simulate

build:
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/pkg/peripheral_msi_wb_pkg.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/arbiter/peripheral_msi_arbiter.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/cdc/peripheral_msi_cc561_wb.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/cdc/peripheral_msi_cdc_wb.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/cdc/peripheral_msi_sync2_pgen_wb.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/core/peripheral_msi_arbiter_wb.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/core/peripheral_msi_data_resize_wb.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/core/peripheral_msi_interface_wb.vhd
	ghdl -a --std=08 ../../../../../../rtl/vhdl/wb/core/peripheral_msi_mux_wb.vhd
	ghdl -a --std=08 ../../../../../../bench/vhdl/tests/core/wb/peripheral_msi_testbench.vhd

simulate:
	ghdl -m --std=08 peripheral_msi_testbench
	ghdl -r --std=08 peripheral_msi_testbench --ieee-asserts=disable-at-0 --disp-tree=inst > peripheral_msi_testbench.tree

clean:
	rm -f *.cf *.tree
