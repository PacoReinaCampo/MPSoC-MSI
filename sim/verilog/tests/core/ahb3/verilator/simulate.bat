@echo off
call ../../../../../../settings64_verilator.bat

verilator -Wno-lint --cc -f system.vc --top-module peripheral_msi_testbench
pause
