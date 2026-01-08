# RISC_V_GRP_10
SystemVerilog implementation of a 3-stage pipelined RISC-V processor

## Overview
The processor features a 3-stage pipeline:
1. **IF (Instruction Fetch)**: Fetches instructions from ROM
2. **ID (Instruction Decode)**: Decodes instructions, reads register file, handles branch logic
3. **EX (Execute)**: Performs ALU operations


## Project Structure
Still under development, the project structure is as follows:
```
RISC_V/
├── RISC_V.srcs/
│   ├── sources_1/new/          # RTL source files
│   │   ├── datapath.sv         # Top-level datapath
│   │   ├── IF.sv               # Instruction Fetch stage
│   │   ├── ID.sv               # Instruction Decode stage
│   │   ├── EX.sv               # Execute stage
│   │   ├── instruction_memory.sv  # Synchronous ROM
│   │   ├── types_pkg.sv        # Package definitions
│   │   └── rom.mem             # Instruction memory initialization
│   ├── sim_1/new/              # Testbenches
│   │   └── datapath_tb.sv      # Datapath testbench with pass/fail checking
│   └── constrs_1/new/          # Constraint files
│       └── constraints.xdc
└── RISC_V.xpr                  # Vivado project file
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

### Running Simulation
1. Navigate to the simulation directory:
   ```bash
   cd RISC_V/RISC_V.sim/sim_1/behav/xsim
   ```
2. Run the batch files:
   ```bash
   compile.bat
   elaborate.bat
   simulate.bat
   ```
   
Or use Vivado GUI:
- Click "Run Simulation" → "Run Behavioral Simulation"

### Writing Test Programs
Edit `rom.mem` to load your program. Format: one 32-bit hex instruction per line.

Example program:
```
00B08093    # addi x1, x1, 11
00C10113    # addi x2, x2, 12
00D18193    # addi x3, x3, 13
001080B3    # add  x1, x1, x1
00210133    # add  x2, x2, x2
003181B3    # add  x3, x3, x3
00208533    # add  a0, x1, x2
00000073    # ecall (halt)
```

### Testbench
The testbench (`datapath_tb.sv`) automatically:
- Waits for `CPURun` to go low (ECALL halt)
- Compares register `a0` (x10) against an expected value
- Reports TEST PASS or TEST FAIL

Set the expected value in `datapath_tb.sv`:
```systemverilog
localparam logic [31:0] EXPECTED_A0 = 32'd<your_value>;
```

## Features in Detail

### ECALL Halt Mechanism
- When ECALL (`0x00000073`) is decoded, `CPURun` latches low
- PC stops advancing, no further instructions execute
- Remains halted until reset is asserted


## Contributors
Group 10
