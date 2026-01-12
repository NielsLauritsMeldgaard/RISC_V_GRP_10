`timescale 1ns / 1ps
// notes for this module; the mux going to addr adder uses the aluSrc signal 
//as select, and it is unclear whether this implementation is valid.
// there is unfinished forwarding logic in this file.
// U and J types instructions are missing and unclear if all branch functions work!
module ID(
    input  logic        clk, rst,
    input  logic [31:0] instr_in,      // Wire from IF
    input  logic [31:0] pc_in,         // Wire from IF
    input  logic [31:0] rd_data_wb, 
    input  logic [4:0]  rd_addr_wb, 
    input  logic        regWrite_wb, 
    input  logic [31:0] ex_res,
    input  logic        fwd_mem_wdata,
    input  logic        branch_taken,  
    output logic [31:0] rs1_data, rs2_immData,
    output logic [31:0] imm,
    output logic [4:0]  Daddr,
    output logic [31:0] Ddata,
    output logic [31:0] pc_out,        
    output logic [4:0]  aluCtrl_piped,
    output logic        memToReg_piped, memRead_piped, memWrite_piped, regWrite_piped,
    output logic [4:0]  rd_addr_piped
    );
    typedef enum logic [2:0] { IMM_I, IMM_S, IMM_B, IMM_U, IMM_J } imm_sel_t;

    logic [6:0]  opcode;
    logic [4:0]  rs1, rs2, rd;
    logic aluSrc, memToReg, regWrite, memRead, memWrite, branch;
    logic [4:0] aluCtrl;
    logic [2:0] imm_sel;
    // Register file
    logic [31:0] rs2_data; 
    logic [31:0] IR_next;
    
    // --- PIPELINE REGISTERS (IR and PC) ---
    logic [31:0] IR, pc_id;
    always_ff @(posedge clk) begin
        if (rst) begin
            IR    <= 32'h00000013; // NOP
            pc_id <= 0;
        end else begin
            IR    <=IR_next;
            pc_id <= pc_in;
        end
    end

    

    regFile regFile (
     .clk(clk), .rst(rst), .we(regWrite_wb),         
     .rs1_addr(IR[19:15]), .rs2_addr(IR[24:20]),   
     .rd_addr(rd_addr_wb), .rd_data(rd_data_wb),    
     .rs1_data(rs1_data), .rs2_data(rs2_data) 
    );

    
    
    always_comb begin
         // Decoding from IR
         IR_next =  branch_taken ? 32'h00000013 : instr_in;
         rs1    = IR[19:15];
         rs2    = IR[24:20];
         rd     = IR[11:7];
         opcode = IR[6:0];
          case (imm_sel)
             IMM_I: imm = {{20{IR[31]}}, IR[31:20]};
             IMM_S: imm = {{20{IR[31]}}, IR[31:25], IR[11:7]};
             IMM_B: imm = {{19{IR[31]}}, IR[31], IR[7], IR[30:25], IR[11:8], 1'b0};
             default: imm = 32'b0;
         endcase
         
          aluSrc = 0; memToReg = 0; regWrite = 0; memRead = 0; memWrite = 0; branch = 0; aluCtrl = 5'b0;
          imm_sel = IMM_I; 

         case (opcode)
            7'b0110011: begin regWrite = 1; aluCtrl = {1'b0,IR[14:12],IR[30]}; end
            7'b0010011: begin aluSrc = 1; regWrite = 1; aluCtrl = {1'b0,IR[14:12],1'b0}; end
            7'b0000011: begin aluSrc = 1; memToReg = 1; regWrite = 1; memRead = 1; end
            7'b0100011: begin aluSrc = 1; memWrite = 1; imm_sel = IMM_S; end
            7'b1100011: begin branch = 1; aluCtrl = {1'b1,IR[14:12],1'b0}; imm_sel = IMM_B; end
            default: ;    
         endcase
         
         pc_out         = pc_id;
         aluCtrl_piped  = aluCtrl;
         memToReg_piped = memToReg;
         memRead_piped  = memRead;
         memWrite_piped = memWrite;
         regWrite_piped = regWrite;
         rd_addr_piped  = rd;
         
         rs2_immData = aluSrc ? imm : rs2_data; // Fixed: now uses internal rs2_data
        
         Daddr = rs1_data + imm; 
         Ddata = fwd_mem_wdata ? ex_res : rs2_data; 
         
        
    end
endmodule