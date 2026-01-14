`timescale 1ns / 1ps

module tb_datapath();

    logic clk, rst;
    int tests_passed = 0;
    int total_tests = 6;

    // Instantiate Datapath
    datapath #(.MEM_WORDS(128)) dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock Generation (10ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Helper Task: Check Write-Back ---
    // Watches the Write-Back bus and compares result with expected value
    task check_register(input [4:0] reg_addr, input [31:0] expected, input string name);
        begin
            // Wait for the specific register to be targeted with Write Enable HIGH
            // and ensure we aren't looking at a stall cycle
            wait(dut.rW_wb == 1'b1 && dut.rd_wb == reg_addr && !dut.stall);
            @(negedge clk); // Sample at the end of the valid cycle
            if (dut.ex_res === expected) begin
                $display("[PASS] %s: x%0d = %0d", name, reg_addr, expected);
                tests_passed++;
            end else begin
                $display("[FAIL] %s: x%0d Expected %0d, Got %0d", name, reg_addr, expected, dut.ex_res);
            end
            @(posedge clk); // Move to next cycle to avoid double-counting
        end
    endtask

    initial begin
        // 1. Initialize and Reset
        rst = 1;
        #25;
        rst = 0;
        $display("\n==================================================");
        $display("   STARTING RISC-V FORWARDING & PIPELINE TEST     ");
        $display("==================================================");

        // 2. Test EX-to-EX Forwarding (Chain)
        // Instruction 0x00: ADDI x1, x0, 10
        check_register(5'd1, 32'd10, "Base Load x1");
        
        // Instruction 0x04: ADDI x2, x1, 20 (Forward x1 from EX_RES_REG)
        // Expected: 10 + 20 = 30
        check_register(5'd2, 32'd30, "Forward x1 -> x2");

        // Instruction 0x08: ADD x3, x1, x2 (Forward x2 from EX_RES_REG)
        // Expected: 10 + 30 = 40
        check_register(5'd3, 32'd40, "Forward x2 -> x3");

        // 3. Test Store Forwarding
        // Instruction 0x0C: SW x3, 8(x0) (Forward x3 value to Memory)
        wait(dut.dwb_we == 1'b1 && dut.dwb_ack == 1'b1);
        @(posedge clk); #1;
        if (dut.data_mem.mem[2] === 32'd40) begin // 8 >> 2 = index 2
            $display("[PASS] Store Forwarding: Mem[8] = 40");
            tests_passed++;
        end else begin
            $display("[FAIL] Store Forwarding: Mem[8] = %d (Expected 40)", dut.data_mem.mem[2]);
        end

        // 4. Test Load and Load-to-Use Forwarding
        // Instruction 0x10: LW x4, 8(x0)
        check_register(5'd4, 32'd40, "Memory Load x4");

        // Instruction 0x18: ADDI x5, x4, 5 (Forward x4 from Memory result)
        // Expected: 40 + 5 = 45
        check_register(5'd5, 32'd45, "Load-to-Use Forward x4 -> x5");

        // 5. Test Branch Logic and IR Flushing
        // Instruction 0x1C: BEQ x5, x5, 8 (Jump to 0x24)
        // Instruction 0x20: ADDI x1, x0, 1 (This SHOULD NOT execute)
        // Instruction 0x24: ADDI x10, x0, 123 (Final Target)
        
        // We wait for the x10 write. If we see a write to x1=1, branch failed.
        fork
            begin
                wait(dut.rW_wb == 1'b1 && dut.rd_wb == 5'd1 && dut.ex_res == 32'd1);
                $display("[FAIL] Branch Logic: Instruction at 0x20 was not flushed!");
            end
            begin
                check_register(5'd10, 32'd123, "Branch Target Result x10");
            end
        join_any
        disable fork;

        // --- Final Summary ---
        $display("\n==================================================");
        $display("TEST SUMMARY: %0d / %0d Passed", tests_passed, total_tests);
        if (tests_passed == total_tests)
            $display("RESULT: SYSTEM FULLY FUNCTIONAL WITH FORWARDING");
        else
            $display("RESULT: SYSTEM HAS LOGIC ERRORS");
        $display("==================================================\n");

        #100;
        $finish;
    end

    // Monitor for Pipeline Debugging
    initial begin
        $monitor("T: %t | Stall: %b | PC: %h | IR: %h | WB: x%0d=%d | FwdSrc: %b", 
                 $time, dut.stall, dut.pc_id, dut.id_stage.IR, dut.rd_wb, dut.ex_res, dut.aluFwdSrc);
    end

endmodule