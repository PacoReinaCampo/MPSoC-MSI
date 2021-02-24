@echo off
SET PATH=C:\apps\Microsemi\Libero_SoC_v11.8\Modelsim\win32acoem;%PATH%

vlib work
vlog -sv -f system.vc
vsim -c -do run.do work.peripheral_bfm_testbench
pause
