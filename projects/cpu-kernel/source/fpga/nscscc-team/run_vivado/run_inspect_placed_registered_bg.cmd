@echo off
cd /d D:\version-2\fpga\nscscc-team\run_vivado
call C:\Xilinx\Vivado\2023.2\bin\vivado.bat -mode batch -notrace -nojournal -log inspect_placed_registered.log -source inspect_placed_registered.tcl
exit /b %errorlevel%
