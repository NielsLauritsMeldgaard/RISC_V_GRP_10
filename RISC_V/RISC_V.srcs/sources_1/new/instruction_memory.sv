`timescale 1ns / 1ps



module instruction_memory #(
    parameter MEM_WORDS = 1024             
)(
    input  logic         clk,
    input  logic [31:0]  pc,               
    output logic [31:0]  instr             
);
    localparam MEM_ADDR_BITS = $clog2(MEM_WORDS);
    (* rom_style = "block" *) // force blockram
    logic [31:0] mem [0:MEM_WORDS-1];
    
    initial begin
        $readmemh("C:/Users/amads/02144_riscV/RISC_V_GRP_10/RISC_V/RISC_V.srcs/sim_1/new/program.hex", mem); // Comment this out if using TB to load
        
    end

    
    always_ff @(posedge clk) begin
        instr <= mem[pc >> 2];
    end

endmodule