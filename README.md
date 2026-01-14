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


## Contributors
Group 10