# Verilator Simulation Testbench

This directory contains a C++ testbench for use with Verilator, replicating the functionality of `testbench.sv`.

## Features

- Loads `.mem` programs into the DUT bootloader memory
- Loads expected register values from `.res` files (little-endian binary format)
- Runs until ECALL instruction is encountered
- Compares actual register state with expected values
- Command-line argument support for test selection and cycle limits
- GitHub Actions CI integration
- Cross-platform: Linux, macOS, and Windows support

## Prerequisites

### Linux/macOS
```bash
sudo apt-get install -y verilator cmake make
```

### Windows
Two options:

**Option 1: Windows Subsystem for Linux (WSL) - Recommended**
```bash
wsl
sudo apt-get update && sudo apt-get install -y verilator cmake make
```

**Option 2: Native Windows (requires MinGW/MSYS2)
- Install [Verilator](https://www.veripool.org/wiki/verilator/Installation) for Windows
- Install [CMake](https://cmake.org/download/)
- Install [MinGW](https://www.mingw-w64.org/) or [MSYS2](https://www.msys2.org/)
- Ensure `cmake`, `verilator`, and `make` are in your PATH

## Building

### Linux/macOS
```bash
cd tests/verilator_simulation
chmod +x run_test.sh
./run_test.sh
```

### Windows (PowerShell)
```powershell
cd tests\verilator_simulation
.\run_test.ps1
```

### Windows (WSL)
```bash
cd tests/verilator_simulation
./run_test.sh
```

### Custom Test
```bash
# Linux/macOS
TEST=task1/addpos CYCLES=100000 ./run_test.sh

# Windows PowerShell
.\run_test.ps1 -Test "task1/addpos" -Cycles 100000
```

## Command-Line Arguments

### Bash Script (Linux/macOS)
- `+TEST=name` – Specify test name (e.g., `gcd_benchmark`, `task1/addpos`)
- `+CYCLES=N` – Set maximum simulation cycles (default: 10000000)
- `+TESTROOT=path` – Override test root directory (default: `tests/`)

### PowerShell Script (Windows)
```powershell
.\run_test.ps1 -Test "task1/addpos" -Cycles 100000 -TestRoot "custom/path"
```

## File Format

### `.mem` Files
Hex-encoded program memory (one word per line, 32-bit values).

### `.res` Files
Binary register dump: 32 registers × 4 bytes each, little-endian.

## CI Integration

The testbench integrates with GitHub Actions (Linux). Add to your workflow:

```yaml
- name: Verilator Simulation Tests
  run: |
    cd tests/verilator_simulation
    for test in task1/* task2/* task3/*; do
      TEST="$(basename $test .mem)" ./run_test.sh || exit 1
    done
```

## Register Access

The testbench accesses register values via:
```cpp
dut->rootp->datapath__DOT__id_stage__DOT__regFile__DOT__regs[i]
```

This path must match your design hierarchy. Adjust if your module hierarchy differs.

## Troubleshooting

### Include Path Errors
After the first build, reload your IDE:
- **VS Code**: Ctrl+Shift+P → "Developer: Reload Window"
- **CLion**: File → Invalidate Caches

### CMake Not Found (Windows)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# Then try again
```

### Make Not Found (Windows)
You're likely missing MinGW. Install via:
- [MinGW-w64](https://www.mingw-w64.org/) (standalone)
- [MSYS2](https://www.msys2.org/) (pacman-based)

Verify:
```powershell
where cmake
where verilator
where make
```

### ECALL Timeout
Increase `+CYCLES` or check for infinite loops in your program:
```bash
./run_test.sh +CYCLES=50000000
```

### Test Files Missing
Verify `.mem` and `.res` files exist in the test directory.

## Output

The testbench produces standardized output:

```
[TB] Loading program tests/gcd_benchmark.mem
[TB] Loading expected results from tests/gcd_benchmark.res
[TB]   x1 = 0x00000005
[TB] ECALL detected at cycle 12345 (IR=0x00000073)
[TB] PASS gcd_benchmark
[TB] Summary: 1 total, 1 passed, 0 failed
```

