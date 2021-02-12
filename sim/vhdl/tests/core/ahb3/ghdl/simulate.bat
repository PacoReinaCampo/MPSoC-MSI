@echo off
call ../../../../../../settings64_ghdl.bat

ghdl -a --std=08 ../../../../../../rtl/vhdl/ahb3/pkg/mpsoc_msi_ahb3_pkg.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/ahb3/core/mpsoc_msi_ahb3_interface.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/ahb3/core/mpsoc_msi_ahb3_slave_port.vhd
ghdl -a --std=08 ../../../../../../rtl/vhdl/ahb3/core/mpsoc_msi_ahb3_master_port.vhd
ghdl -a --std=08 ../../../../../../bench/vhdl/tests/core/ahb3/mpsoc_msi_testbench.vhd
ghdl -m --std=08 mpsoc_msi_testbench
ghdl -r --std=08 mpsoc_msi_testbench --ieee-asserts=disable-at-0 --disp-tree=inst > mpsoc_msi_testbench.tree
pause
