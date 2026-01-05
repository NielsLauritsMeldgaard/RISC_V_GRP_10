`timescale 1ns / 1ps

module datapath(
        input logic clk,
        input logic rst        
    );
    
    localparam int INSTR_MEM_SIZE = 8;
    localparam string FILE_NAME = "rom.mem";
    
    logic [31:0] instruction;
    
    IFs #(
        .INSTR_MEM_SIZE(INSTR_MEM_SIZE),
        .FILE_NAME(FILE_NAME)
    ) IF_u (
        .clk(clk),
        .rst(rst),
        .mux_sel(0), // HARDCODED FOR NOW
        .pc_offset(0), // HARDCODED FOR NOW
        .instruction(instruction)        
    );
    
endmodule
