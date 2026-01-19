@echo off
REM RISC-V UART Bootloader Upload
REM Edit PROGRAM, PORT, and BAUD below as needed

REM ===== CONFIGURATION =====
set "PROGRAM=programs/hello_world.bin"
set "PORT=COM10"
set "BAUD=115200"
REM ==========================

cd /d "%~dp0" || exit /b 1

echo.
echo ================================
echo RISC-V UART Bootloader Upload
echo ================================
echo Program: %PROGRAM%
echo Port: %PORT%
echo Baud: %BAUD%
echo.

py -3 uart_loader.py %PROGRAM% --port %PORT% --baud %BAUD%

echo.
pause
exit /b %errorlevel%