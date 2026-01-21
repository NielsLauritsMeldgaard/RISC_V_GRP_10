#!/usr/bin/env bash
# Verilator testbench build and run script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Script is at: RISC_V_GRP_10/RISC_V/tests/verilator_simulation
# Go up 3 levels to RISC_V_GRP_10, then navigate from there

PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
RISC_V_ROOT="$PROJECT_ROOT/RISC_V"
TEST_ROOT="$PROJECT_ROOT/tests"
BUILD_DIR="$SCRIPT_DIR/build"

# Configuration
TEST="${TEST:-gcd_benchmark}"
CYCLES="${CYCLES:-10000000}"
TESTROOT="$TEST_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Verilator Test Runner${NC}"
echo "Test: $TEST"
echo "Max Cycles: $CYCLES"
echo "RISC-V Root: $RISC_V_ROOT"
echo "Test Root: $TESTROOT"

# Verify sources exist
SOURCES=$(find "$RISC_V_ROOT/RISC_V.srcs/sources_1/new" -name "*.sv")
if [ -z "$SOURCES" ]; then
    echo -e "${RED}ERROR: No SystemVerilog sources found${NC}"
    exit 1
fi

echo -e "${YELLOW}Found SystemVerilog sources:${NC}"
echo "$SOURCES"

# Create build directory
mkdir -p "$BUILD_DIR"

# Run CMake and build
echo -e "${YELLOW}Configuring with CMake...${NC}"
cd "$BUILD_DIR"
cmake .. || {
    echo -e "${RED}ERROR: CMake configuration failed${NC}"
    exit 1
}

echo -e "${YELLOW}Building with Make...${NC}"
make -j 4 || {
    echo -e "${RED}ERROR: Build failed${NC}"
    exit 1
}

# Run simulation
cd "$SCRIPT_DIR"
echo -e "${YELLOW}Running simulation...${NC}"
"$BUILD_DIR/testbench_verilator" \
    "+TESTROOT=$TESTROOT/" \
    "+TEST=$TEST" \
    "+CYCLES=$CYCLES"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Test completed successfully${NC}"
    exit 0
else
    echo -e "${RED}Test failed${NC}"
    exit 1
fi

