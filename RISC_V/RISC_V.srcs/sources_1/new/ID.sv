`timescale 1ns / 1ps

module ID(
        input logic clk,
        input logic rst,
        input logic [31:0] instruction
    );
    
    logic [31:0] regfile [31:0];
    logic [31:0] regfile_next [31:0];
    
    // internal wire
    logic [6:0] opcode;
    
    // Decoded singals to ALU etc
    logic [2:0] funct3;
    logic [6:0] funct7;
    
    always_comb begin
    opcode = instruction[6:0];
    
        //@TODO: FINISH DECODE STAGE
        case (opcode)
            7'b0010011: begin
            end
        endcase
    end
    
endmodule
