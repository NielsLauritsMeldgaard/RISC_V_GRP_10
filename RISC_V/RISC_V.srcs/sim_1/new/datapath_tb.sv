`timescale 1ns / 1ps


module datapath_tb;
    logic clk;
    logic rst;
    
    // DUT
    datapath DUT (
        .rst(rst),
        .clk(clk)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b1;      // assert reset
        #20;             // hold reset
        rst = 1'b0;      // deassert reset

    end

endmodule
