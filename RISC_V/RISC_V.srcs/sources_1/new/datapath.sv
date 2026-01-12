module datapath #(parameter MEM_WORDS = 1024)(input logic clk, rst);
    logic [31:0] pc_w, instr_w, rs1_d, rs2_id, imm, Ddata, pc_id, pc_ex, imm_ex, ex_res;
    logic [4:0] aluOP, rd_id, rd_wb, Daddr;
    logic mToR, mR, mW, rW, br_dec, rW_wb;

    IF_stage #(.MEM_WORDS(MEM_WORDS)) if_stage (
        .clk(clk), .rst(rst), .pc_sel(br_dec), .pc_from_ex(pc_ex), .imm_from_ex(imm_ex),
        .pc_wire(pc_w), .instr_wire(instr_w)
    );

    ID id_stage (
        .clk(clk), .rst(rst), .instr_in(instr_w), .pc_in(pc_w),
        .rd_data_wb(ex_res), .rd_addr_wb(rd_wb), .regWrite_wb(rW_wb),
        .ex_res(ex_res), .fwd_mem_wdata(1'b0),
        .rs1_data(rs1_d), .rs2_immData(rs2_id), .imm(imm), .Daddr(Daddr), .Ddata(Ddata),
        .pc_out(pc_id), .aluCtrl_piped(aluOP), .memToReg_piped(mToR),
        .memRead_piped(mR), .memWrite_piped(mW), .regWrite_piped(rW), .rd_addr_piped(rd_id), .branch_taken(br_dec)
    );

    EX #(.MEM_WORDS(MEM_WORDS)) ex_stage (
        .clk(clk), .rst(rst), .rs1_val_reg_next(rs1_d), .rs2_imm_reg_next(rs2_id),
        .addr_next(Daddr), .Wdata_next(Ddata), .pc_next(pc_id), .imm_next(imm),
        .aluOP_next(aluOP), .memToReg_next(mToR), .memRead_next(mR), .memWrite_next(mW),
        .regWrite_next(rW), .rd_addr_next(rd_id), .aluFwdSrc(2'b00),
        .ex_res(ex_res), .rd_addr_out(rd_wb), .regWrite_out(rW_wb),
        .pc_out(pc_ex), .imm_out(imm_ex), .branch_decision(br_dec)
    );
endmodule