`timescale 1ns / 1ps
import types_pkg::*;


module ex_stage(
        input logic clk,
        input logic rst,
        input logic [31:0] ALUSrc1, ALUSrc2,
        input logic [3:0] ALUOp,
        output logic [31:0] result
    );
    
    
    
    // ALU output
    logic [31:0] ALU_res, ALU_in1, ALU_in2;
    
    
    always_comb begin                      
        //@TODO: temporary set to always be op1/2. Implement muxes to select between writeback/memory output or registers
        ALU_in1 = ALUSrc1;
        ALU_in2 = ALUSrc2;
        
        if (ALUOp[3]) begin
            case (ALUOp[2:0])
                3'b000: ALU_res = ALU_in1 != ALU_in2;
                3'b001: ALU_res = ALU_in2; // LUI: just pass through the immediate (already shifted)
                default: ALU_res = 32'b0;
            endcase
        end else begin
            case (ALUOp[2:0])
                3'b000: ALU_res = ALU_in1 & ALU_in2;
                3'b001: ALU_res = ALU_in1 | ALU_in2; 
                3'b010: ALU_res = $signed(ALU_in1) + $signed(ALU_in2);
                3'b110: ALU_res = $signed(ALU_in1) - $signed(ALU_in2);
                default: ALU_res = 32'b0; // def case
            endcase
        end
        
        //@TODO: make result be based on a mux selecting between ALU and Mem (currently just ALU result)
        result = ALU_res;
                                    
    end    
    
endmodule
