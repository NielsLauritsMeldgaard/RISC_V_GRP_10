 `timescale 1ns / 1ps

 module tb_datapath();

     logic clk, rst;

     // Simple clock/reset
     initial begin
         clk = 0;
         forever #5 clk = ~clk;
     end

     // DUT
     datapath #(.MEM_WORDS(128)) dut (
         .clk(clk),
         .rst(rst)
     );

     // ------------ Test control ------------
     // XSim runs from RISC_V/RISC_V.sim/sim_1/behav/xsim
     // So we need to go up 4 levels to reach RISC_V/, then into tests/
     string test_root = "../../../../tests/";   // default root (relative to sim run dir)
     string test = "task1/";              // test name like "task1/addpos"
     int cycles = 10000000;                         // default max cycles per test
     int passed, failed;
     
     // Allow +arg to overwrite
     initial begin
        void'($value$plusargs("TESTROOT=%s", test_root));
        void'($value$plusargs("CYCLES=%d", cycles));
        void'($value$plusargs("TEST=%s", test));
    end

     
     // HELPERS
     
     task automatic load_program(string memfile);
         $display("[TB] Loading program %s", memfile);
         $readmemh(memfile, dut.instr_mem.mem);
     endtask
     
      task automatic load_expected(string resfile, output logic [31:0] exp[32]);
         int fd; int bytes_read; byte buffer[4];
         for (int i = 0; i < 32; i++) exp[i] = 32'h0;
         
         fd = $fopen(resfile, "rb");  // Open in binary mode
         if (!fd) $fatal(1, "[TB] Cannot open %s", resfile);
         
         $display("[TB] Loading expected results from %s", resfile);
         
         // Read 32 registers × 4 bytes each (little-endian)
         for (int i = 0; i < 32; i++) begin
             bytes_read = $fread(buffer, fd);
             if (bytes_read == 4) begin
                 // Little-endian: buffer[0] is LSB, buffer[3] is MSB
                 exp[i] = {buffer[3], buffer[2], buffer[1], buffer[0]};
                 if (exp[i] != 0) begin
                     $display("[TB]   x%0d = 0x%08h", i, exp[i]);
                 end
             end else if (bytes_read > 0) begin
                 $warning("[TB] Incomplete read for register x%0d", i);
             end
         end
         $fclose(fd);
     endtask
     
     function automatic bit compare_regs(logic [31:0] exp[32]);
         bit ok = 1;
         for (int i = 0; i < 32; i++) begin
             logic [31:0] act = dut.id_stage.regFile.regs[i];
             if (act !== exp[i]) begin
                 ok = 0;
                 $display("[TB] Mismatch x%0d exp=%08h got=%08h", i, exp[i], act);
             end
         end
         return ok;
     endfunction
     
     task automatic reset_dut();
         rst = 1'b1;
         repeat (4) @(posedge clk);
         rst = 1'b0;
     endtask
     
     // Wait for ECALL instruction (opcode 0x73, full instr = 0x00000073)
     task automatic wait_for_ecall();
         int timeout = cycles;  // Use cycles as timeout
         int cycle_count = 0;
         logic [31:0] current_instr;
         
         forever begin
             @(posedge clk);
             cycle_count++;
             
             // Check instruction in ID stage
             current_instr = dut.id_stage.IR;
             
             // ECALL: opcode = 0x73 (bits [6:0] = 7'b1110011)
             if (current_instr[6:0] == 7'b1110011 && current_instr[31:7] == 25'b0) begin
                 $display("[TB] ECALL detected at cycle %0d (IR=0x%08h)", cycle_count, current_instr);
                 repeat (2) @(posedge clk);
                 break;
             end
             
             // Timeout check
             if (cycle_count >= timeout) begin
                 $warning("[TB] Timeout: ECALL not found after %0d cycles", timeout);
                 break;
             end
         end
     endtask
     
     task automatic run_one(string tname);
         string memfile = {test_root, tname, ".mem"};
         string resfile = {test_root, tname, ".res"};
         logic [31:0] exp[32];

         load_program(memfile);
         load_expected(resfile, exp);
         reset_dut();
         wait_for_ecall();  // Run until ECALL instead of fixed cycles

         if (compare_regs(exp)) begin
             passed++;
             $display("[TB] PASS %s", tname);
         end else begin
             failed++;
             $display("[TB] FAIL %s", tname);
         end
     endtask

     // ------------ Main ------------
     initial begin
         // Wait one time unit so plusargs are parsed
         #1;
         if (test == "") $fatal(1, "[TB] No tests specified");

         run_one(test);

        $display("[TB] Summary: %0d total, %0d passed, %0d failed",
                 passed + failed, passed, failed);
         $finish;
     end
     
     
 endmodule


// `timescale 1ns / 1ps

// module tb_datapath();

//     logic clk, rst;

//     // Simple clock/reset
//     initial begin
//         clk = 0;
//         forever #5 clk = ~clk;
//     end

//     // DUT
//     datapath #(.MEM_WORDS(128)) dut (
//         .clk(clk),
//         .rst(rst)
//     );

//     // ------------ Test control ------------
//     string test_root = "RISC_V/tests/";   // default root (relative to sim run dir)
//     string tests[$];                       // list of test names like "task1/addpos"
//     int cycles = 2000;                     // default max cycles per test

//     int total, passed, failed;

//     // Allow overrides via plusargs
//     initial begin
//         string single;
//         string csv;

//         if ($value$plusargs("TESTROOT=%s", test_root)) begin end
//         if ($value$plusargs("CYCLES=%d", cycles)) begin end

//         // Single test: +TEST=task1/addpos
//         if ($value$plusargs("TEST=%s", single)) begin
//             tests.push_back(single);
//         end else if ($value$plusargs("TESTS=%s", csv)) begin
//             // Comma separated list: +TESTS=task1/addpos,task1/addneg
//             string rest = csv;
//             int comma;
//             while (rest.len() > 0) begin
//                 comma = rest.find(",");
//                 if (comma == -1) begin
//                     tests.push_back(rest);
//                     rest = "";
//                 end else begin
//                     tests.push_back(rest.substr(0, comma-1));
//                     rest = rest.substr(comma+1);
//                 end
//             end
//         end else begin
//             // Default small set; extend as needed
//             // tests = '{"task1/addpos","task1/addneg","task1/addlarge"};
//             tests = '{"task1/addpos"};
//         end
//     end

//     // ------------ Helpers ------------
//     task automatic load_program(string memfile);
//         $display("[TB] Loading program %s", memfile);
//         $readmemh(memfile, dut.instr_mem.mem);
//     endtask

//     task automatic load_expected(string resfile, output logic [31:0] exp[32]);
//         int fd; string line; int idx; int unsigned val; int rc;
//         for (int i = 0; i < 32; i++) exp[i] = 32'h0;
//         fd = $fopen(resfile, "r");
//         if (!fd) $fatal(1, "[TB] Cannot open %s", resfile);
//         while (!$feof(fd)) begin
//             void'($fgets(line, fd));
//             rc = $sscanf(line, "x%0d %h", idx, val);
//             if (rc == 2 && idx >= 0 && idx < 32) exp[idx] = val;
//         end
//         $fclose(fd);
//     endtask

//     function automatic bit compare_regs(logic [31:0] exp[32]);
//         bit ok = 1;
//         for (int i = 0; i < 32; i++) begin
//             logic [31:0] act = dut.id_stage.regFile.regs[i];
//             if (act !== exp[i]) begin
//                 ok = 0;
//                 $display("[TB] Mismatch x%0d exp=%08h got=%08h", i, exp[i], act);
//             end
//         end
//         return ok;
//     endfunction

//     task automatic reset_dut();
//         rst = 1'b1;
//         repeat (4) @(posedge clk);
//         rst = 1'b0;
//     endtask

//     task automatic run_one(string tname);
//         string memfile = {test_root, tname, ".mem"};
//         string resfile = {test_root, tname, ".res"};
//         logic [31:0] exp[32];

//         total++;
//         load_program(memfile);
//         load_expected(resfile, exp);
//         reset_dut();
//         repeat (cycles) @(posedge clk);

//         if (compare_regs(exp)) begin
//             passed++;
//             $display("[TB] PASS %s", tname);
//         end else begin
//             failed++;
//             $display("[TB] FAIL %s", tname);
//         end
//     endtask

//     // ------------ Main ------------
//     initial begin
//         // Wait one time unit so plusargs are parsed
//         #1;
//         if (tests.size() == 0) $fatal(1, "[TB] No tests specified");

//         foreach (tests[i]) run_one(tests[i]);

//         $display("[TB] Summary: %0d total, %0d passed, %0d failed", total, passed, failed);
//         $finish;
//     end

// endmodule