`timescale 1ns / 1ps


module datapath_tb;
    logic clk;
    logic rst;
    logic CPURun;
    logic [31:0] a0;
    localparam logic [31:0] EXPECTED_A0 = 32'h2cc; // set expected value here
    
    // DUT
    datapath DUT (
        .rst(rst),
        .clk(clk),
        .CPURun_out(CPURun),
        .a0_value_out(a0)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b1;      // assert reset
        #10;             // hold reset
        rst = 1'b0;      // deassert reset

    end

    // Stop when CPURun goes low and check a0
    initial begin
        @(negedge rst); // wait for reset deassert
        wait (CPURun == 1'b0);
        if (a0 === EXPECTED_A0) begin
            $display("TEST PASS: a0 == %0d", a0);
            $finish;
        end else begin
            $fatal(1, "TEST FAIL: a0=%0d expected=%0d", a0, EXPECTED_A0);
        end
    end

endmodule
