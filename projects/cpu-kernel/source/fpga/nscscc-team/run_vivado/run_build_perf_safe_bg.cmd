@echo off
cd /d D:\version-2\fpga\nscscc-team\run_vivado
call C:\Xilinx\Vivado\2023.2\bin\vivado.bat -mode batch -notrace -nojournal -log build_perf_safe_to_place.log -source build_perf_safe_to_place.tcl
exit /b %errorlevel%
