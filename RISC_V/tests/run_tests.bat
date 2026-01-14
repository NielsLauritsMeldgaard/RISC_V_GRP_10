@echo off
REM RISC-V Testbench Runner - Windows Batch
REM Edit TASKS below to change which tasks to run

REM ===== CONFIGURATION (edit this section) =====
REM Task(s) to run - change these as needed
set "TASKS=task1"
REM Timeout per test in seconds
set "TIMEOUT=60"
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
    python bin_to_mem.py %%T
)

echo.
echo Step 2: Running simulations...
echo.

REM Step 2: Run tests
python run_testbench.py --task %TASKS% --timeout %TIMEOUT%

pause
exit /b %errorlevel%
