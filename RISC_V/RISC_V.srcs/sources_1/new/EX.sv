module EX #(parameter MEM_WORDS = 1024)(
    input  logic clk, rst,
    input  logic [31:0] rs1_val_reg_next, rs2_imm_reg_next, Wdata_next, pc_next, imm_next,
    input  logic [4:0]  aluOP_next, rd_addr_next, addr_next,
    input  logic memToReg_next, memRead_next, memWrite_next, regWrite_next,
    input  logic [1:0] aluFwdSrc,
    output logic [31:0] ex_res, pc_out, imm_out,
    output logic [4:0] rd_addr_out,
    output logic regWrite_out, branch_decision
    );

    logic [31:0] rs1_reg, rs2_reg, ex_res_reg, addr_reg, Wdata_reg, pc_reg, imm_reg;
    logic [4:0]  aluOP_reg, rd_reg;
    logic        mToReg_reg, mRead_reg, mWrite_reg, rWrite_reg;
    logic [31:0] op1, op2, Rdata, aluRes;

    data_memory #(.MEM_WORDS(MEM_WORDS)) data_mem (
        .clk(clk), .addr(addr_reg), .Wdata(Wdata_reg),
        .En(mRead_reg), .We(mWrite_reg), .Rdata(Rdata), .rst(rst)
    );  
     
    ALU ALU_unit (.op1(op1), .op2(op2), .aluOP(aluOP_reg), .res(aluRes));
    
    always_comb begin
        case (aluFwdSrc)
            2'b00:   begin op1 = rs1_reg; op2 = rs2_reg; end 
            2'b01:   begin op1 = rs1_reg; op2 = ex_res_reg; end
            2'b10:   begin op1 = ex_res_reg; op2 = rs2_reg; end
            2'b11:   begin op1 = ex_res_reg; op2 = ex_res_reg; end
            default: begin op1 = rs1_reg; op2 = rs2_reg; end
        endcase
        ex_res = mToReg_reg ? Rdata : aluRes;
        rd_addr_out = rd_reg; regWrite_out = rWrite_reg;
        branch_decision = aluOP_reg[4] & aluRes[0];
        pc_out = pc_reg; imm_out = imm_reg;
    end
    
   always_ff @(posedge clk) begin
      if (rst) begin
          {rs1_reg, rs2_reg, ex_res_reg, addr_reg, Wdata_reg, pc_reg, imm_reg} <= '0;
          {aluOP_reg, rd_reg, mToReg_reg, mRead_reg, mWrite_reg, rWrite_reg} <= '0;
      end else begin
          rs1_reg <= rs1_val_reg_next; rs2_reg <= rs2_imm_reg_next;
          addr_reg <= addr_next; Wdata_reg <= Wdata_next;
          pc_reg <= pc_next; imm_reg <= imm_next;
          aluOP_reg <= aluOP_next; rd_reg <= rd_addr_next;
          mToReg_reg <= memToReg_next; mRead_reg <= memRead_next;
          mWrite_reg <= memWrite_next; rWrite_reg <= regWrite_next;
          ex_res_reg <= ex_res;
      end
   end
endmodule