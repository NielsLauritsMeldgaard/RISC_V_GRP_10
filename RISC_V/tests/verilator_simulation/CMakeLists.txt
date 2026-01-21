cmake_minimum_required(VERSION 3.12)
project(risc_v_verilator_testbench CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Verilator
find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator not found. Install with: sudo apt-get install verilator")
endif()

# Get all SystemVerilog sources
file(GLOB_RECURSE SV_SOURCES "../../RISC_V/RISC_V.srcs/sources_1/new/*.sv")
if(NOT SV_SOURCES)
    message(FATAL_ERROR "No SystemVerilog sources found in RISC_V/RISC_V.srcs/sources_1/new")
endif()

message(STATUS "Found SystemVerilog sources: ${SV_SOURCES}")

# Create Verilator module
add_executable(testbench_verilator 
    tb_verilator.cpp
)

verilate(testbench_verilator
    SOURCES ${SV_SOURCES}
    TOP_MODULE datapath
    VERILATOR_ARGS 
        --trace
        --Wall
        --Wno-DECLFILENAME
        -Wwarn-UNUSEDSIGNAL
        -Wwarn-UNUSEDPARAM
)

# Add verilator libraries
target_link_libraries(testbench_verilator verilator)
