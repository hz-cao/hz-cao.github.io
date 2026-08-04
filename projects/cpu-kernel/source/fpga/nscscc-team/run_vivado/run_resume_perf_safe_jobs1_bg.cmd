@echo off
cd /d D:\version-2\fpga\nscscc-team\run_vivado
call C:\Xilinx\Vivado\2023.2\bin\vivado.bat -mode batch -notrace -nojournal -log resume_perf_safe_jobs1.log -source resume_perf_safe_jobs1.tcl
exit /b %errorlevel%
