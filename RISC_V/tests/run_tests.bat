@echo off
REM RISC-V Testbench Runner - Windows Batch
REM Edit TASKS below to change which tasks to run

REM ===== CONFIGURATION (edit this section) =====
REM Task(s) to run - change these as needed
set "TASKS=task1"
REM Timeout per test in seconds
set "TIMEOUT=60"
REM Optional: Path to xsim.bat (set if auto-detect fails)
REM Example: set "XSIM_PATH=C:\Xilinx\Vivado\2024.1\bin\xsim.bat"
set "XSIM_PATH="
REM ============================================

cd /d "%~dp0" || exit /b 1

echo.
echo ================================
echo RISC-V Test Runner
echo ================================
echo Working directory: %CD%
echo Tasks to run: %TASKS%
echo.

REM Step 1: Convert binaries to memory files
echo Step 1: Converting binary files...
echo.
for %%T in (%TASKS%) do (
    echo Converting %%T...
    py -3 bin_to_mem.py %%T
)

echo.
echo Step 2: Running simulations...
echo.

REM Step 2: Run tests
set "CMD=py -3 run_testbench.py --task %TASKS% --timeout %TIMEOUT%"
if defined XSIM_PATH set "CMD=%CMD% --xsim-path \"%XSIM_PATH%\""
%CMD%

pause
exit /b %errorlevel%
