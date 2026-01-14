# RISC-V Test Suite

## Quick Start

### Run Tests (Windows)
```bash
run_tests.bat
```

### Run Tests (Linux/macOS)
```bash
chmod +x run_tests.sh
./run_tests.sh
```

Both scripts automatically:
1. Convert binary test files to memory format
2. Run xsim simulations
3. Report pass/fail results

Tip: If auto-detection of xsim fails, set the path in the scripts:
- Windows: edit `run_tests.bat` and set `XSIM_PATH` to your `xsim.bat`
- Linux/macOS: edit `run_tests.sh` and set `XSIM_PATH` to your `xsim` binary

Or pass it directly:
```bash
py -3 run_testbench.py --task task1 --xsim-path "C:\\Xilinx\\Vivado\\2024.1\\bin\\xsim.bat"
```

## Configuring Tests

Edit the scripts to change which tasks to run:

**Windows (`run_tests.bat`):**
```bat
set "TASKS=task1"                    # Run task1
set "TASKS=task1 task2"              # Run task1 and task2
```

**Linux/macOS (`run_tests.sh`):**
```bash
TASKS="task1"                        # Run task1
TASKS="task1 task2"                  # Run task1 and task2
```

## Manual Testing

Run specific tests with Python directly:

```bash
# Convert binaries to memory files first
python bin_to_mem.py task1

# Run all tests in task1
python run_testbench.py --task task1

# Run single test
python run_testbench.py --test task1/addpos

# Run all tests
python run_testbench.py
```

## Tasks

The following tasks are taken directly from the repo: cae-lab

### Task 1

- Simple instructions testing for arithmetic operations (add, sub, and, or, xor, sll, srl, sra, slt, sltu)
- Immediate instructions (addi, andi, ori, xori, slli, srli, srai, slti, sltiu)


### Task 2

- Branch instructions (beq, bne, blt, bge, bltu, bgeu)

### Task 3
(Not ready yet, tests needs to be rewritten as memory cannot be 1 MB, but rather 12KB due to FPGA limitations)

In this task, you'll add support for:
- Function calls
- Load and store instructions
- Stack pointer (SP) initialized by the program (set to 1 MB in example code)
- Provide 1 MB of memory in your processor