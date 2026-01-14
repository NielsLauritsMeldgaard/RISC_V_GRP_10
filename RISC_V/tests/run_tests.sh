#!/bin/bash
# RISC-V Testbench Runner - Linux/macOS Bash
# Edit TASKS below to change which tasks to run

# ===== CONFIGURATION (edit this section) =====
# Task(s) to run - change these as needed
TASKS="task1"
# Timeout per test in seconds
TIMEOUT=60
# ============================================

cd "$(dirname "$0")" || exit 1

echo ""
echo "================================"
echo "RISC-V Test Runner"
echo "================================"
echo "Working directory: $(pwd)"
echo "Tasks to run: $TASKS"
echo ""

# Step 1: Convert binaries to memory files
echo "Step 1: Converting binary files..."
echo ""
for task in $TASKS; do
    echo "Converting $task..."
    python bin_to_mem.py "$task"
done

echo ""
echo "Step 2: Running simulations..."
echo ""

# Step 2: Run tests
python run_testbench.py --task $TASKS --timeout $TIMEOUT
