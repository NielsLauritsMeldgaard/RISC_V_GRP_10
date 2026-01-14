# RISC_V_GRP_10

[![SystemVerilog CI](https://github.com/NielsLauritsMeldgaard/RISC_V_GRP_10/actions/workflows/systemverilog-ci.yml/badge.svg)](https://github.com/USERNAME/RISC_V_GRP_10/actions/workflows/systemverilog-ci.yml)

SystemVerilog implementation of a 3-stage pipelined RISC-V processor

## Overview
The processor features a 3-stage pipeline:
1. **IF (Instruction Fetch)**: Fetches instructions from ROM
2. **ID (Instruction Decode)**: Decodes instructions, reads register file, handles branch logic
3. **EX (Execute)**: Performs ALU operations


## Source Code Structure
```
RISC_V_GRP_10/
├── RISC_V/
│   ├── RISC_V.srcs/
│   │   ├── sources_1/new/              # RTL source files
│   │   │   ├── datapath.sv             # Top-level datapath module
│   │   │   ├── IF.sv                   # Instruction Fetch stage
│   │   │   ├── ID.sv                   # Instruction Decode stage
│   │   │   ├── EX.sv                   # Execute stage
│   │   │   ├── ALU.sv                  # Arithmetic Logic Unit
│   │   │   ├── regFile.sv              # 32×32-bit register file
│   │   │   ├── instruction_memory.sv   # 128 KB instruction memory
│   │   │   ├── data_memory.sv          # 64 KB data memory
│   │   │   └── forwarding_unit.sv      # Data hazard forwarding unit
```

## Getting Started

### Prerequisites
- Xilinx Vivado (tested with Vivado 2023.x+)
- Windows/Linux environment

### Opening the Project
1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd RISC_V_GRP_10
   ```
2. Open Vivado
3. Open the project file: `RISC_V/RISC_V.xpr`
4. Vivado will automatically regenerate the build directories

## Testing

Comprehensive automated test suite with both simple scripts and advanced Python tools.

### Quick Start - Run Tests with Scripts

The easiest way to run tests - just execute the script for your OS:

**Windows:**
```bash
RISC_V\tests\run_tests.bat
```

**Linux/macOS:**
```bash
RISC_V/tests/run_tests.sh
```

Both scripts automatically convert binaries and run all configured tests. Edit the script to change which tasks to run.

### Full Testing Documentation

For detailed testing instructions, configuration options, and manual testing, see [RISC_V/tests/README.md](RISC_V/tests/README.md)

This includes:
- ✅ Automated test execution (Windows batch & Bash scripts)
- ✅ Python-based test orchestration
- ✅ Binary to memory file conversion
- ✅ Register comparison against expected results
- ✅ ECALL-based test termination
- ✅ Multi-Vivado version support

### Prerequisites
- Vivado 2022.x or later (xsim simulator)
- Python 3.x
- Test binaries (.bin files) and expected results (.res files)

### Test Structure
```
RISC_V/tests/
├── task1/                  # Task 1 test programs
│   ├── addpos.bin         # Binary test program
│   ├── addpos.mem         # Hex memory file (generated)
│   ├── addpos.res         # Expected register results
│   └── ...
├── task2/                  # Task 2 test programs
├── run_tests.bat          # Windows test runner script (easy - just run!)
├── run_tests.sh           # Linux/macOS test runner script
├── run_testbench.py       # Advanced Python test orchestrator
├── program.py             # Binary to .mem converter
└── README.md              # Detailed testing documentation
```

## Contributors
Group 10