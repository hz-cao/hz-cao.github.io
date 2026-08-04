@echo off
cd /d D:\version-2\fpga\nscscc-team\run_vivado
call C:\Xilinx\Vivado\2023.2\bin\vivado.bat -mode batch -notrace -nojournal -log resume_perf_impl_full.log -source resume_perf_impl.tcl
exit /b %errorlevel%
