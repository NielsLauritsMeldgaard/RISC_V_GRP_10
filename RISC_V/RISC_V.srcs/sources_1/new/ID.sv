`timescale 1ns / 1ps
import types_pkg::*;

module id_stage(
        input logic clk,
        input logic rst,
        input logic [4:0] wr_idx, 
        input logic wr_en, // from EX pipeline reg
        input logic [31:0] instr_if,
        input logic [31:0] reg_din,
        input logic flush,
        output logic [31:0] ALUSrc1_next, ALUSrc2_next,
        output logic wr_en_next,
        output logic [3:0] ALUOp_next,
        output logic [4:0] wr_idx_next,
        output logic CPURun_next,
        output logic [31:0] a0_value_out,
        output logic branch_next,
        output logic [31:0] pc_offset_next,
        output logic [3:0] mem_byte_en,
        output logic [31:0] mem_addr,
        output logic mem_wr_en,
        //output logic mem_rd_en,
        output logic [31:0] mem_dataWr,
        output logic [2:0] mem_funct3_next,
        output logic mem_to_reg_next        
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
    logic [31:0] Reg1, Reg2;
    
    always_comb begin
        // Wire the output from IM directly to the input of the instruction register        
        instr_next_de = flush ? 32'h00000013 /* nop */ : instr_if;
                
        // From decode (align everything to the pipelined instruction)
        opcode = instr_de[6:0];
        wr_idx_next = instr_de[11:7];
        funct3 = instr_de[14:12];        
        funct7 = instr_de[31:25];
        rs1 = instr_de[19:15]; // Read combinatorically ATM
        rs2 = instr_de[24:20]; // Read combinatorically ATM               
        
        // Default
        ALUSrc2Sel = 0;
        wr_en_next = 0;
        ALUOp_next = 0;
        CPURun_next = 1;
        imm = 0;
        branch_next = 0;
        pc_offset_next = 0;
        mem_byte_en = 0;
        mem_wr_en = 0;
        //mem_rd_en = 0;
        mem_funct3_next = 0;
        mem_to_reg_next = 0;
        
        case (opcode)
            7'b0010011: begin // I_type
                ALUSrc2Sel = 1;
                wr_en_next = 1;
                imm = {{20{instr_de[31]}}, instr_de[31:20]};
                case(funct3) 
                   3'h7: ALUOp_next = 4'b0000; // and
                   3'h6: ALUOp_next = 4'b0001; // or
                   3'h0: ALUOp_next = 4'b0010; // add  
                endcase    
            end
            
            7'b0110011: begin // R_type
                wr_en_next = 1;
                case(funct3) 
                   3'h7: ALUOp_next = 4'b0000; // and
                   3'h6: ALUOp_next = 4'b0001; // or
                   3'h0: ALUOp_next = funct7[6] ? 4'b0110 : 4'b0010; // sub / add    
                endcase            
            end
            
            7'b1100011: begin // B_type
                branch_next = 1'b1;
                
                imm = { {19{instr_de[31]}},  // sign extension
               instr_de[31],        // imm[12]
               instr_de[7],         // imm[11]
               instr_de[30:25],     // imm[10:5]
               instr_de[11:8],      // imm[4:1]
               1'b0 };
               
               pc_offset_next = imm;
               
               case(funct3)
                    3'h1: ALUOp_next = 4'b1000; // != (bne)
               endcase                           
            end
            
            // LUI (Load Upper Immediate) - opcode 0110111
            7'b0110111: begin // U_type (LUI)
                wr_en_next = 1;
                ALUSrc2Sel = 1;
                // LUI immediate: load into upper 20 bits, zero lower 12 bits
                imm = {instr_de[31:12], 12'b0};
                ALUOp_next = 4'b1001; // LUI operation
            end
            
            7'b0100011: begin // S type (store)
                // S-type immediate: sign-extended from bits [31:25] and [11:7]
                imm = {{20{instr_de[31]}}, instr_de[31:25], instr_de[11:7]};
                mem_wr_en = 1'b1;
                //mem_funct3_next = funct3;
                case (funct3)
                    3'h0: mem_byte_en = 4'b0001; // SB: store byte
                    3'h1: mem_byte_en = 4'b0011; // SH: store halfword
                    3'h2: mem_byte_en = 4'b1111; // SW: store word
                    default: mem_byte_en = 4'b0000;
                endcase                
            end
            
            7'b0000011: begin // L type (load)
                wr_en_next = 1;
                // I-type immediate for address offset
                imm = {{20{instr_de[31]}}, instr_de[31:20]};
                //mem_rd_en = 1'b1;
                mem_to_reg_next = 1'b1; // select memory data for writeback
                mem_funct3_next = funct3;
                // case (funct3)
                //     3'h0: mem_byte_en = 4'b0001; // LB: load byte (sign-extended)
                //     3'h1: mem_byte_en = 4'b0011; // LH: load halfword (sign-extended)
                //     3'h2: mem_byte_en = 4'b1111; // LW: load word
                //     3'h4: mem_byte_en = 4'b0001; // LBU: load byte (zero-extended)
                //     3'h5: mem_byte_en = 4'b0011; // LHU: load halfword (zero-extended)
                //     default: mem_byte_en = 4'b0000;
                // endcase            
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
        Reg1 = regfile[rs1];
        Reg2 = regfile[rs2];
        ALUSrc1_next = Reg1;
        ALUSrc2_next = (ALUSrc2Sel ? imm : Reg2); // This is a mux
        // Debug/verification output: current value of x10 (a0)
        a0_value_out = regfile[10];
        
        mem_addr = Reg1 + imm;
        mem_dataWr = Reg2;
    end
    
    
    // Sequential logic for registers
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 32; i++)
                regfile[i] <= 32'h0;
                //instr_de <= 0;
            
            //regfile[1] <= 32'd77; // Test value            
        end else begin
            for (int i = 0; i < 32; i++)
                regfile[i] <= regfile_next[i];
            
            
            instr_de <= instr_next_de;            
        end            
    end
    
//    always_ff @(posedge clk or posedge rst) begin
//        if (rst) begin
//            instr_de <= 0;          
//        end else begin
//            instr_de <= instr_next_de;          
//        end            
//    end
    
    
    
    
    
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
