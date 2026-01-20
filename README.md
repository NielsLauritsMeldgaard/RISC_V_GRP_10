
# RISC_V_GRP_10

[![SystemVerilog CI](https://github.com/NielsLauritsMeldgaard/RISC_V_GRP_10/actions/workflows/systemverilog-ci.yml/badge.svg)](https://github.com/USERNAME/RISC_V_GRP_10/actions/workflows/systemverilog-ci.yml)

SystemVerilog implementation of a 3-stage pipelined RISC-V processor.

## Overview
The processor features a 3-stage pipeline:
1. **IF (Instruction Fetch)**: Fetches instructions from ROM.
2. **ID (Instruction Decode)**: Decodes instructions, reads register file, handles branch logic.
3. **EX (Execute)**: Performs ALU operations.

## Source Code Structure
```text
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
2. Open Vivado.
3. Open the project file: `RISC_V/RISC_V.xpr`.
4. Vivado will automatically regenerate the build directories.

## Testing

Comprehensive automated test suite with both simple scripts and advanced Python tools.

### Quick Start - Run Tests with Scripts

The easiest way to run tests is to execute the script for your OS:

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

For detailed testing instructions, configuration options, and manual testing, see [RISC_V/tests/README.md](RISC_V/tests/README.md).

This includes:
-  Automated test execution (Windows batch & Bash scripts).
-  Python-based test orchestration.
-  Binary to memory file conversion.
-  Register comparison against expected results.
-  ECALL-based test termination.
-  Multi-Vivado version support.

---

## Benchmark Competition: GCD Test

To objectively measure the performance of this processor against others, we use a standard **Greatest Common Divisor (GCD)** benchmark.

### The Goal
The "fastest" processor is the one that executes the benchmark correctly in the shortest absolute time.

$$ \text{Execution Time} = \text{Total Clock Cycles} \times \text{Clock Period} $$

A processor design that achieves a lower CPI (Cycles Per Instruction) or supports a higher Clock Frequency ($F_{max}$) without logical errors will achieve the best score.

### The Algorithm
The program performs the following steps:
1. Loads 1 pair of numbers into registers immediately.
2. Loads 3 other pairs and stores them into Data Memory.
3. Calculates GCD for the current pair using Euclidean subtraction.
4. Overwrites the original pair in Memory with `{Result, 0}`.
5. Fetches the next pair from memory and repeats.
6. Finishes when all 4 pairs are processed.

### Assembly Source
The reference assembly code (compiled for Base Address `0x20000000`):

```assembly
.globl _start

_start:
    # ----------------------------------------------------
    # 1. SETUP & LOAD PHASES
    # ----------------------------------------------------
    li s0, 0x20000000    # s0 holds the base address 0x2000_0000
    li s1, 4            # s1 is our Loop Counter (4 pairs)

    # --- Load Pair 1 (Keep in Registers x10, x11 for first run) ---
    li x10, 1000000     # Pair 1 Value A
    li x11, 3540094     # Pair 1 Value B

    # --- Load Pair 2 (Save to Mem Offset 0x08) ---
    li t0, 500          # Pair 2 Value A
    li t1, 250          # Pair 2 Value B
    sw t0, 8(s0)        # Store A at 0x2000_0008
    sw t1, 12(s0)       # Store B at 0x2000_000C

    # --- Load Pair 3 (Save to Mem Offset 0x10) ---
    li t0, 27           # Pair 3 Value A
    li t1, 81           # Pair 3 Value B
    sw t0, 16(s0)       # Store A at 0x2000_0010
    sw t1, 20(s0)       # Store B at 0x2000_0014

    # --- Load Pair 4 (Save to Mem Offset 0x18) ---
    li t0, 12           # Pair 4 Value A
    li t1, 16           # Pair 4 Value B
    sw t0, 24(s0)       # Store A at 0x2000_0018
    sw t1, 28(s0)       # Store B at 0x2000_001C
    
    # Keep a pointer to the current pair being processed
    mv s2, s0           # s2 will act as our moving pointer

    # ----------------------------------------------------
    # 2. MAIN LOOP
    # ----------------------------------------------------
process_loop:
    # At this point, x10 and x11 contain the numbers to calculate

gcd_start:
    # --- GCD ALGORITHM (Euclidean Subtraction) ---
    beq x10, x11, gcd_done
    blt x10, x11, swap_sub
    sub x10, x10, x11
    j gcd_start

swap_sub: 
    sub x11, x11, x10
    j gcd_start

gcd_done:
    # Result is now in x10
    
    # --- WRITE RESULT TO MEMORY ---
    sw x10, 0(s2)       # Store GCD result 
    sw x0,  4(s2)       # Store Zero

    # --- PREPARE FOR NEXT LOOP ---
    addi s1, s1, -1     # Decrement counter
    beq s1, x0, program_end

    # --- FETCH NEXT PAIR ---
    addi s2, s2, 8      # Move pointer
    lw x10, 0(s2)       # Load next Value A
    lw x11, 4(s2)       # Load next Value B
    j process_loop

program_end:  
    ecall
```

### Standard Machine Code
If your processor's Data Memory starts at **0x20000000**, you can use this hex code directly.  
Save this as `gcd_std.mem`:

```text
20000437
00400493
000f4537
24050513
003605b7
47e58593
1f400293
0fa00313
00542423
00642623
01b00293
05100313
00542823
00642a23
00c00293
01000313
00542c23
00642e23
00040913
00b50c63
00b54663
40b50533
ff5ff06f
40a585b3
fedff06f
00a92023
00092223
fff48493
00048a63
00890913
00092503
00492583
fcdff06f
00000073
```
### Expected Final State (After Program Completion)

After correct execution of the GCD benchmark, the processor must reach the following architectural state.

---

#### Register File (Hexadecimal)

x5 := 0x0000000C
x6 := 0x00000010
x8 := 0x20000000
x10 := 0x00000004
x11 := 0x00000004
x18 := 0x20000018

yaml
Kopier kode

---

#### Data Memory Contents

Let:

baseAddr = 0x20000000

wasm
Kopier kode

Expected memory layout:

DataMem:

0x00 (baseAddr) := 0x00000002
0x04 (baseAddr) := 0x00000000

0x08 (baseAddr) := 0x000000FA
0x0C (baseAddr) := 0x00000000

0x10 (baseAddr) := 0x0000001B
0x14 (baseAddr) := 0x00000000

0x18 (baseAddr) := 0x00000004
0x1C (baseAddr) := 0x00000000

---

### Adapting to Your Address Space (Patching)
If your processor design uses a different Data Memory base (e.g., `0x00010000` or `0x80000000`), the standard machine code will fail because the first instruction (`li s0, BASE`) will point to the wrong location.

**How to Patch:**
We have provided a Python script in `tests/patch_mem.py`. This script rewrites the first instruction of the hex file to match your specific base address.

**Usage:**
```bash
# Syntax: python patch_mem.py <input_mem> <output_mem> <new_base_address_hex>

# Example: Changing base to 0x00010000
python patch_mem.py gcd_std.mem gcd_mycpu.mem 0x00010000
```


## Contributors
Group 10
