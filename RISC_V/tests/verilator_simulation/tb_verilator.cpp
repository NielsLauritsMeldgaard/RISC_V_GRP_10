#include <iostream>
#include <fstream>
#include <vector>
#include <cstring>
#include <cstdint>
#include <filesystem>
#include "Vdatapath.h"
#include "verilated.h"

namespace fs = std::filesystem;

// Global Verilator context
VerilatedContext* contextp = nullptr;
Vdatapath* dut = nullptr;
uint64_t main_time = 0;

// Verilator callback for time
double sc_time_stamp() {
    return main_time;
}

// Load .mem file into bootloader memory
void load_program(const std::string& memfile) {
    std::cout << "[TB] Loading program " << memfile << std::endl;
    std::ifstream file(memfile);
    if (!file.is_open()) {
        std::cerr << "[TB] ERROR: Cannot open " << memfile << std::endl;
        exit(1);
    }

    std::string line;
    int addr = 0;
    while (std::getline(file, line) && addr < 128) {
        if (line.empty()) continue;
        // Parse hex value
        uint32_t val = static_cast<uint32_t>(std::stoul(line, nullptr, 16));
        dut->rootp->datapath__DOT__bootloader__DOT__mem[addr++] = val;
    }
    file.close();
}

// Load .res file (expected register values)
void load_expected(const std::string& resfile, std::vector<uint32_t>& exp) {
    exp.clear();
    exp.resize(32, 0);

    std::ifstream file(resfile, std::ios::binary);
    if (!file.is_open()) {
        std::cerr << "[TB] ERROR: Cannot open " << resfile << std::endl;
        exit(1);
    }

    std::cout << "[TB] Loading expected results from " << resfile << std::endl;

    // Read 32 registers × 4 bytes each (little-endian)
    for (int i = 0; i < 32; i++) {
        uint8_t buffer[4] = {0, 0, 0, 0};
        file.read(reinterpret_cast<char*>(buffer), 4);
        
        if (file.gcount() == 4) {
            // Little-endian: buffer[0] is LSB, buffer[3] is MSB
            exp[i] = (buffer[3] << 24) | (buffer[2] << 16) | (buffer[1] << 8) | buffer[0];
            if (exp[i] != 0) {
                std::cout << "[TB]   x" << i << " = 0x" << std::hex << exp[i] << std::dec << std::endl;
            }
        } else if (file.gcount() > 0) {
            std::cerr << "[TB] WARNING: Incomplete read for register x" << i << std::endl;
        }
    }
    file.close();
}

// Compare actual registers with expected
bool compare_regs(const std::vector<uint32_t>& exp) {
    bool ok = true;
    for (int i = 0; i < 32; i++) {
        uint32_t act = dut->rootp->datapath__DOT__id_stage__DOT__regFile__DOT__regs[i];
        if (act != exp[i]) {
            ok = false;
            std::cout << "[TB] Mismatch x" << i << " exp=0x" << std::hex << exp[i] 
                      << " got=0x" << act << std::dec << std::endl;
        }
    }
    return ok;
}

// Reset DUT
void reset_dut() {
    dut->rst = 0;
    dut->clk = 0;
    dut->eval();
    main_time += 5;

    dut->clk = 1;
    dut->eval();
    main_time += 5;

    dut->rst = 1;
    for (int i = 0; i < 4; i++) {
        dut->clk = 0;
        dut->eval();
        main_time += 5;
        dut->clk = 1;
        dut->eval();
        main_time += 5;
    }
    dut->rst = 0;
    dut->clk = 0;
    dut->eval();
    main_time += 5;
}

// Wait for ECALL instruction (opcode 0x73)
void wait_for_ecall(int max_cycles) {
    int cycle_count = 0;
    
    for (cycle_count = 0; cycle_count < max_cycles; cycle_count++) {
        dut->clk = 1;
        dut->eval();
        main_time += 5;
        
        // Check for ECALL: opcode = 0x73 (bits [6:0] = 0b1110011)
        uint32_t ir = dut->rootp->datapath__DOT__id_stage__DOT__IR;
        if ((ir & 0x7F) == 0x73 && (ir >> 7) == 0) {
            std::cout << "[TB] ECALL detected at cycle " << cycle_count 
                      << " (IR=0x" << std::hex << ir << std::dec << ")" << std::endl;
            
            // Two more clock cycles
            for (int i = 0; i < 2; i++) {
                dut->clk = 0;
                dut->eval();
                main_time += 5;
                dut->clk = 1;
                dut->eval();
                main_time += 5;
            }
            return;
        }
        
        dut->clk = 0;
        dut->eval();
        main_time += 5;
    }
    
    std::cerr << "[TB] WARNING: Timeout - ECALL not found after " << max_cycles << " cycles" << std::endl;
}

// Run one test
bool run_one(const std::string& test_name, const std::string& test_root, int max_cycles) {
    std::string memfile = test_root + test_name + ".mem";
    std::string resfile = test_root + test_name + ".res";
    std::vector<uint32_t> exp;

    // Check if files exist
    if (!fs::exists(memfile)) {
        std::cerr << "[TB] ERROR: " << memfile << " not found" << std::endl;
        return false;
    }
    if (!fs::exists(resfile)) {
        std::cerr << "[TB] ERROR: " << resfile << " not found" << std::endl;
        return false;
    }

    load_program(memfile);
    load_expected(resfile, exp);
    reset_dut();
    wait_for_ecall(max_cycles);

    bool result = compare_regs(exp);
    if (result) {
        std::cout << "[TB] PASS " << test_name << std::endl;
    } else {
        std::cout << "[TB] FAIL " << test_name << std::endl;
    }
    return result;
}

int main(int argc, char** argv) {
    // Initialize Verilator context
    contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);

    // Create DUT
    dut = new Vdatapath{contextp};

    // Test parameters
    std::string test_root = "tests/";
    std::string test = "gcd_benchmark";
    int max_cycles = 10000000;

    // Parse command-line arguments
    for (int i = 1; i < argc; i++) {
        std::string arg = argv[i];
        if (arg.find("+TESTROOT=") == 0) {
            test_root = arg.substr(10);
            if (test_root.back() != '/') test_root += '/';
        } else if (arg.find("+TEST=") == 0) {
            test = arg.substr(6);
        } else if (arg.find("+CYCLES=") == 0) {
            max_cycles = std::stoi(arg.substr(8));
        }
    }

    std::cout << "[TB] Test root: " << test_root << std::endl;
    std::cout << "[TB] Test: " << test << std::endl;
    std::cout << "[TB] Max cycles: " << max_cycles << std::endl;

    if (test.empty()) {
        std::cerr << "[TB] ERROR: No test specified (use +TEST=name)" << std::endl;
        delete dut;
        delete contextp;
        return 1;
    }

    // Run test
    int passed = 0, failed = 0;
    if (run_one(test, test_root, max_cycles)) {
        passed++;
    } else {
        failed++;
    }

    std::cout << "[TB] Summary: " << (passed + failed) << " total, " 
              << passed << " passed, " << failed << " failed" << std::endl;

    // Cleanup
    delete dut;
    delete contextp;

    return (failed > 0) ? 1 : 0;
}
