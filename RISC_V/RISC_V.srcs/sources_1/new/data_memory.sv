`timescale 1ns / 1ps

module data_memory #(
    parameter MEM_WORDS = 1024 
)(
    input  logic         clk,
    input  logic         rst,        // Global synchronous reset
    input  logic [31:0]  addr,
    input  logic [31:0]  Wdata,
    input  logic         En,         // High ONLY for Read
    input  logic         We,         // High ONLY for Write
    output logic [31:0]  Rdata             
);
    // Force the array to be mapped to Block RAM by the synthesizer
    (* ram_style = "block" *) 
    logic [31:0] mem [0:MEM_WORDS-1];

    // Initialize memory to zero (Synthesizable power-on state)
    initial begin
        for (int i = 0; i < MEM_WORDS; i++) begin
            mem[i] = 32'h0;
        end
    end

    // WRITE: synchronous write on clock edge
    always_ff @(posedge clk) begin
        if (rst) begin
            // nothing needed for mem reset (initialized in initial block)
        end else if (We) begin
            mem[addr >> 2] <= Wdata;
        end
    end

    // READ: combinational (asynchronous) read for immediate data availability
    always_comb begin
        if (En) begin
            Rdata = mem[addr >> 2];
        end else begin
            Rdata = 32'h0;
        end
    end

endmodule