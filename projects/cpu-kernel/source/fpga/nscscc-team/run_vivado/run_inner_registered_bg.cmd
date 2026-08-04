@echo off
cd /d D:\version-2\fpga\nscscc-team\run_vivado
call C:\Xilinx\Vivado\2023.2\bin\vivado.bat -mode batch -notrace -nojournal -log resume_inner_registered.log -source resume_perf_debug.tcl -tclargs 60000000
exit /b %errorlevel%
