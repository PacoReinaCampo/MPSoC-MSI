@echo off
call ../../../../../../settings64_ghdl.bat

ghdl -a --std=08 ../../../../../../rtl/vhdl/pkg/peripheral/wb/peripheral_msi_pkg_wb.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/peripheral/wb/arbiter/peripheral_msi_arbiter.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/peripheral/wb/cdc/peripheral_msi_cc561_wb.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/peripheral/wb/cdc/peripheral_msi_cdc_wb.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/peripheral/wb/cdc/peripheral_msi_sync2_pgen_wb.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/peripheral/wb/main/peripheral_msi_arbiter_wb.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/peripheral/wb/main/peripheral_msi_data_resize_wb.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/peripheral/wb/main/peripheral_msi_interface_wb.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/peripheral/wb/main/peripheral_msi_mux_wb.vhd
ghdl -a --std=08 ../../../../../../bench/vhdl/tests/peripheral/wb/peripheral_msi_testbench.vhd
ghdl -m --std=08 peripheral_msi_testbench
ghdl -r --std=08 peripheral_msi_testbench --ieee-asserts=disable-at-0 --disp-tree=inst > peripheral_msi_testbench.tree
pause
