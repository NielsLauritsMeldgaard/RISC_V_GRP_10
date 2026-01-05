`timescale 1ns / 1ps

module IFs #(
        parameter int INSTR_MEM_SIZE = 8,
        parameter string FILE_NAME = "rom.mem"
    )(
        input logic clk,
        input logic rst,
        //@TODO: perhaps rename
        input logic mux_sel,
        input logic [31:0] pc_offset,
        output logic [31:0] instruction
    );
                
        logic [$clog2(INSTR_MEM_SIZE * 4) - 1 : 0] pc, pc_next; // The width should be four times greater to make up for bytewise offset (0, 4, 8... N * 4)     
        logic [31:0] mux_out;       
        
        // Init the instruction memory
        sync_rom #(
            .MEM_SIZE_WORDS(INSTR_MEM_SIZE),
            .FILE_NAME(FILE_NAME)
        ) IM (
            .clk(clk),
            .addr(pc >> 2), // The BRAM takes chronological address from .mem file (0, 1, 2... N)
            .dout(instruction)
        );
        
        always_comb begin
            // select between the offset computed from the ALU or the standard 4
            mux_out = (mux_sel ? pc_offset : 4);
            pc_next = mux_out + pc;
        end
        
        // async resets
        always_ff @(posedge clk) begin
            if (rst) begin
                pc <= 0;
            end else begin
                pc <= pc_next;
            end
        end           
        
endmodule
