@echo off
call ../../../../../../settings64_ghdl.bat

ghdl -a --std=08 ../../../../../../rtl/vhdl/ahb3/pkg/peripheral_msi_ahb3_pkg.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/ahb3/core/peripheral_msi_interface_ahb3.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/ahb3/core/peripheral_msi_slave_port_ahb3.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/ahb3/core/peripheral_msi_master_port_ahb3.vhd
ghdl -a --std=08 ../../../../../../bench/vhdl/tests/core/ahb3/peripheral_msi_testbench.vhd
ghdl -m --std=08 peripheral_msi_testbench
ghdl -r --std=08 peripheral_msi_testbench --ieee-asserts=disable-at-0 --disp-tree=inst > peripheral_msi_testbench.tree
pause
