`timescale 1ns / 1ps
import types_pkg::*;


module datapath(
        input logic clk,
        input logic rst,
        output logic CPURun_out,
        output logic [31:0] a0_value_out        
    );
    
    localparam int INSTR_MEM_SIZE = 16;
    localparam string FILE_NAME = "rom.mem";
    
    logic [31:0] instr_if, ALUSrc1_next, ALUSrc2_next, ALUSrc1, ALUSrc2, WB;
    logic wr_en_next, wr_en, CPURun_next, CPURun;
    logic [3:0] ALUOp_next, ALUOp;
    logic [4:0] wr_idx_next, wr_idx;
    
    if_stage #(
        .INSTR_MEM_SIZE(INSTR_MEM_SIZE),
        .FILE_NAME(FILE_NAME)
    ) if_stage_u (
        .clk(clk),
        .rst(rst),        
        .instr(instr_if),
        .CPURun(CPURun)       
    );
    
    id_stage id_stage_u(
        .clk(clk),
        .rst(rst),
        .wr_idx(wr_idx),
        .wr_en(wr_en),
        .instr_if(instr_if),
        .reg_din(WB),
        .ALUSrc1_next(ALUSrc1_next),
        .ALUSrc2_next(ALUSrc2_next),
        .wr_en_next(wr_en_next),
        .ALUOp_next(ALUOp_next),
        .wr_idx_next(wr_idx_next),
        .CPURun_next(CPURun_next),
        .a0_value_out(a0_value_out)
    );
    
    ex_stage ex_stage_u (
        .clk(clk),
        .rst(rst),
        .ALUSrc1(ALUSrc1),
        .ALUSrc2(ALUSrc2),
        .ALUOp(ALUOp),
        .result(WB)   
    );

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ALUSrc1 <= 0;
            ALUSrc2 <= 0;
            wr_en <= 0;
            wr_idx <= 0;
            ALUOp <= 0;
            CPURun <= 1;
        end else begin
            ALUSrc1 <= ALUSrc1_next;
            ALUSrc2 <= ALUSrc2_next;
            wr_en <= wr_en_next;
            wr_idx <= wr_idx_next;
            ALUOp <= ALUOp_next;
            CPURun <= CPURun & CPURun_next; // latch low until reset
        end        
    end
    
        // Expose CPURun to the testbench
        assign CPURun_out = CPURun;
    

endmodule
