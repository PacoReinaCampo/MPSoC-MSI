@echo off
call ../../../../../../settings64_verilator.bat

verilator -Wno-lint +incdir+../../../../../../rtl/verilog/ahb3/pkg --cc -f system.vc --top-module mpsoc_msi_testbench
pause
