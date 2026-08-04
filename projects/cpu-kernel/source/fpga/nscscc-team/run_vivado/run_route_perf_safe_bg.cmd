@echo off
cd /d D:\version-2\fpga\nscscc-team\run_vivado
call C:\Xilinx\Vivado\2023.2\bin\vivado.bat -mode batch -notrace -nojournal -log route_perf_safe.log -source route_perf_safe.tcl
exit /b %errorlevel%
