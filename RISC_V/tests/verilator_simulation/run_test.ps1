# Verilator testbench build and run script for Windows PowerShell

param(
    [string]$Test = "gcd_benchmark",
    [int]$Cycles = 10000000,
    [string]$TestRoot = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Script is at: RISC_V_GRP_10\RISC_V\tests\verilator_simulation
# We need to go up to RISC_V_GRP_10 (up 2 levels: verilator_simulation -> tests -> RISC_V), then to RISC_V

$ProjectRoot = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
# Now at RISC_V_GRP_10

$RiscVRoot = Join-Path $ProjectRoot "RISC_V"
if ([string]::IsNullOrEmpty($TestRoot)) {
    $TestRoot = Join-Path $ProjectRoot "tests"
}
$BuildDir = Join-Path $ScriptDir "build"

Write-Host "Verilator Test Runner" -ForegroundColor Yellow
Write-Host "Test: $Test"
Write-Host "Max Cycles: $Cycles"
Write-Host "RISC-V Root: $RiscVRoot"
Write-Host "Test Root: $TestRoot"

# Verify sources exist
$Sources = @(Get-ChildItem -Path "$RiscVRoot\RISC_V.srcs\sources_1\new" -Filter "*.sv" -Recurse)
if ($Sources.Count -eq 0) {
    Write-Host "ERROR: No SystemVerilog sources found" -ForegroundColor Red
    exit 1
}

Write-Host "Found SystemVerilog sources:" -ForegroundColor Yellow
$Sources | ForEach-Object { Write-Host "  $_" }

# Check if CMake and Verilator are available
try {
    $null = cmake --version
} catch {
    Write-Host "ERROR: CMake not found. Install from https://cmake.org/download/" -ForegroundColor Red
    exit 1
}

try {
    $null = verilator --version
} catch {
    Write-Host "ERROR: Verilator not found. Install from https://www.veripool.org/wiki/verilator" -ForegroundColor Red
    Write-Host "Or use WSL: wsl sudo apt-get install verilator" -ForegroundColor Yellow
    exit 1
}

# Create build directory
if (-not (Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir | Out-Null
}

# Run CMake and build
Write-Host "Configuring with CMake..." -ForegroundColor Yellow
Push-Location $BuildDir
try {
    & cmake .. -G "Unix Makefiles" 2>&1 | Tee-Object -Variable cmakeOutput
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: CMake configuration failed" -ForegroundColor Red
        exit 1
    }

    Write-Host "Building with Make..." -ForegroundColor Yellow
    & make -j 4 2>&1 | Tee-Object -Variable makeOutput
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Build failed" -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

# Run simulation
Write-Host "Running simulation..." -ForegroundColor Yellow
$ExePath = Join-Path $BuildDir "testbench_verilator.exe"
if (-not (Test-Path $ExePath)) {
    # Try without .exe extension (MinGW/MSYS2)
    $ExePath = Join-Path $BuildDir "testbench_verilator"
}

if (-not (Test-Path $ExePath)) {
    Write-Host "ERROR: Executable not found at $ExePath" -ForegroundColor Red
    exit 1
}

& $ExePath "+TESTROOT=$TestRoot/" "+TEST=$Test" "+CYCLES=$Cycles"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Test completed successfully" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Test failed" -ForegroundColor Red
    exit 1
}
