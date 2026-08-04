@echo off
cd /d D:\version-2\fpga\nscscc-team\run_vivado
call C:\Xilinx\Vivado\2023.2\bin\vivado.bat -mode batch -notrace -nojournal -log simulate_func_registered.log -source simulate.tcl -tclargs func
exit /b %errorlevel%
