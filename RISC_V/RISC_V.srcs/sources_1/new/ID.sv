`timescale 1ns / 1ps
import types_pkg::*;

module id_stage(
        input logic clk,
        input logic rst,
        input logic [4:0] wr_idx, 
        input logic wr_en, // from EX pipeline reg
        input logic [31:0] instr_if,
        input logic [31:0] reg_din,
        output logic [31:0] ALUSrc1_next, ALUSrc2_next,
        output logic wr_en_next,
        output logic [3:0] ALUOp_next,
    output logic [4:0] wr_idx_next,
    output logic CPURun_next,
    output logic [31:0] a0_value_out
    );
    // Register file (GPRs)
    logic [31:0] regfile [31:0];
    logic [31:0] regfile_next [31:0];
    
    // instruction register
    logic [31:0] instr_de, instr_next_de;
    
    // internal signals, decode and control    
    logic [4:0] rs1, rs2;
    logic [6:0] opcode;
    logic [31:0] imm;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic ALUSrc2Sel; // internal
    
    always_comb begin
        // Wire the output from IM directly to the input of the instruction register
        instr_next_de = instr_if;
        
        // From decode (align everything to the pipelined instruction)
        opcode = instr_de[6:0];
        wr_idx_next = instr_de[11:7];
        funct3 = instr_de[14:12];        
        funct7 = instr_de[31:25];
        rs1 = instr_de[19:15];
        rs2 = instr_de[24:20];
        
        // Default
        ALUSrc2Sel = 0;
        wr_en_next = 0;
        ALUOp_next = 0;
        CPURun_next = 1;
        imm = 0;
        case (opcode)
            7'b0010011: begin // I_type
                ALUSrc2Sel = 1;
                wr_en_next = 1;
                imm = {20'b0, instr_de[31:20]};
                case(funct3) 
                   3'h7: ALUOp_next = 4'b0000; // and
                   3'h6: ALUOp_next = 4'b0001; // or
                   3'h0: ALUOp_next = 4'b0010; // add    
                endcase    
            end
            
            7'b0110011: begin
                wr_en_next = 1;
                case(funct3) 
                   3'h7: ALUOp_next = 4'b0000; // and
                   3'h6: ALUOp_next = 4'b0001; // or
                   3'h0: ALUOp_next = funct7[6] ? 4'b0110 : 4'b0010; // sub / add    
                endcase            
            end
            
            // SYSTEM class (opcode 1110011). Halt only on exact ECALL (0x00000073)
            7'b1110011: begin
                //if (instr_de == 32'h0000_0073)
                CPURun_next = 0;        
            end                     
        endcase
                                
        // This is a MUX:
        // Write if WrEn and it's not the zero reg 
        for (int i = 0; i < 32; i++)
            regfile_next[i] = regfile[i];
        
        if (wr_en && wr_idx != 0)
            regfile_next[wr_idx] = reg_din;
        
        
        // Module output logic (reg1 and reg2)
        ALUSrc1_next = regfile[rs1];
        ALUSrc2_next = (ALUSrc2Sel ? imm : regfile[rs2]); // This is a mux
        // Debug/verification output: current value of x10 (a0)
        a0_value_out = regfile[10];
    end
    
    
    // Sequential logic for registers
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            instr_de <= 0;
            for (int i = 0; i < 32; i++)
                regfile[i] <= 32'h0;            
        end else begin
            instr_de <= instr_next_de;
            for (int i = 0; i < 32; i++)
                regfile[i] <= regfile_next[i];            
        end
    
    end
    
    
    
endmodule



//module ID(
//        input logic clk,
//        input logic rst,
//        input logic [31:0] instr_if,
//        input logic [31:0] reg_din,
//        output logic [31:0] reg1, reg2
//    );
//    // Register file (GPRs)
//    logic [31:0] regfile [31:0];
//    logic [31:0] regfile_next [31:0];
    
//    // instruction register
//    logic [31:0] IR, IR_next;
    
//    // internal wire
//    logic [6:0] opcode;
    
//    // Decoded singals to ALU etc
//    logic [2:0] funct3;
//    logic [6:0] funct7;
//    logic [4:0] rs1, rs2;
    
//    logic [31:0] imm;
//    logic ALU_src;
    
//    // Control
//    logic wr_en_out;
//    logic [3:0] ALU_op;
//    logic [4:0] rd_out;
    
//    always_comb begin
//        // Wire the output from IM directly to the input of the instruction register
//        IR_next = IR;
        
//        // Decode
//        opcode = IR[6:0];
//        rd_out = IR[11:7];  // Index for write destination register
//        funct3 = IR[14:12];        
//        funct7 = IR[31:25];
        
//        rs1 = IR_next[19:15]; // Index for register 1
//        rs2 = IR_next[24:20]; // Index for register 2
        
//        // Default

        
//        case (opcode)        
//            7'b0010011: begin // I-type                
//                imm = {20'b0, IR[31:20]};
//                ctrl_out.ALUSrc = 1;
//                case (funct3)
//                    3'h7: ctrl_out.ALUSel = 4'b0000; // and
//                    3'h6: ctrl_out.ALUSel = 4'b0001; // or
//                    3'h0: ctrl_out.ALUSel = 4'b0010; // add
//                endcase
//            end
            
//            default: begin
//                ctrl_out.RegWrite = 1'b0;
//                ctrl_out.MemRead  = 1'b0;
//                ctrl_out.MemWrite = 1'b0;
//                ctrl_out.Branch   = 1'b0;
//                ctrl_out.Jump     = 1'b0;
//                ctrl_out.MemToReg = 1'b0;
//                ctrl_out.ALUSrc   = 1'b0;
//                ctrl_out.ALUSel    = 4'b0000;  
//            end
//        endcase
        
//        // This is a MUX:
//        // Write if WrEn and it's not the zero reg 
//        if (ctrl_in.RegWrite == 0 && ctrl_in.rd != 0)
//            regfile_next[ctrl_in.rd] = reg_din_EX;
//        else begin // Else latch previous register data
//            for (int i = 0; i < 32; i++)
//                regfile_next[i] = regfile[i];
//        end
        
//        // Module output logic (reg1 and reg2)
//        reg1_DE = regfile[rs1];
//        reg2_DE = (reg2_mux_sel ? imm : regfile[rs2]); // This is a mux
//    end
    
    
//    // Sequential logic for registers
//    always_ff @(posedge clk or posedge rst) begin
//        if (rst) begin
//            instr_reg_DE <= 0;
//            for (int i = 0; i < 32; i++)
//                regfile[i] <= 32'h0;
            
//        end else begin
//            instr_reg_DE <= instr_reg_DE_next;
//            for (int i = 0; i < 32; i++)
//                regfile[i] <= regfile_next[i];            
//        end
    
//    end
    
    
    
//endmodule
