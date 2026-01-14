module datapath #(
    parameter MEM_WORDS = 1024
)(
    input logic clk, 
    input logic rst
);
    // --- Global Control Signals ---
    logic stall;
    logic br_dec; 
    logic [1:0] aluFwdSrc; // alu forward mux select: high if forwarding of rs1 or rs2 is neccisarry
    logic [4:0]  rs1,rs2;
    logic        fwd_mem_data;

    // --- Instruction Wishbone Bus (I-Bus) ---
    logic [31:0] iwb_adr, iwb_dat;
    logic        iwb_stb, iwb_ack;

    // --- Data Wishbone Bus (D-Bus) ---
    logic [31:0] dwb_adr, dwb_dat_o, dwb_dat_i;
    logic [3:0]  dwb_sel;
    logic        dwb_we, dwb_stb, dwb_ack;

    // --- Pipeline Intermediate Wires ---
    logic [31:0] pc_w, instr_w;             // IF -> ID
    logic [31:0] rs1_d, rs2_id, imm;        // ID -> EX
    logic [31:0] pc_id, pc_ex, imm_ex;      // Pipeline PC/Imm
    logic [31:0] ex_res;                    // EX -> WB Feedback
    logic [4:0]  aluOP, rd_id, rd_wb;       // Control/Reg addrs
    logic [2:0]  funct3_id;                 // For Load slicing
    logic [1:0]  addr_offset_id;            // For Load slicing
    logic        mToR, rW, rW_wb;           // Control signals

    // --- 1. GLOBAL STALL LOGIC ---
    // Stall if we requested something (STB) but haven't got the Acknowledge (ACK)
    assign stall = (iwb_stb && !iwb_ack) || (dwb_stb && !dwb_ack);

    // --- 2. STAGE 1: INSTRUCTION FETCH (IF) ---
    IF_stage if_stage (
        .clk(clk), .rst(rst), .stall(stall),
        .pc_sel(br_dec), .pc_from_ex(pc_ex), .imm_from_ex(imm_ex),
        // Master Bus Ports
        .iwb_adr_o(iwb_adr), .iwb_stb_o(iwb_stb),
        .iwb_dat_i(iwb_dat), .iwb_ack_i(iwb_ack),
        // Outputs to ID
        .pc_if_o(pc_w), .instr_if_o(instr_w)
    );

    // --- 3. STAGE 2: INSTRUCTION DECODE (ID) ---
    ID id_stage (
        .clk(clk), .rst(rst), .stall(stall),
        .instr_id_i(instr_w), .pc_id_i(pc_w),
        .rd_data_wb(ex_res), .rd_addr_wb(rd_wb), .regWrite_wb(rW_wb),
        .ex_res(ex_res), .fwd_mem_wdata(fwd_mem_data), .branch_taken(br_dec),
        // Data Bus Master Ports
        .dwb_adr_o(dwb_adr), .dwb_dat_o(dwb_dat_o),
        .dwb_sel_o(dwb_sel), .dwb_we_o(dwb_we),
        .dwb_stb_o(dwb_stb), .dwb_ack_i(dwb_ack),
        .dwb_cyc_o(), // Optional
        // Pipeline outputs to EX
        .rs1_data(rs1_d), .rs2_immData(rs2_id), .imm_id_o(imm),
        .pc_id_o(pc_id), .aluCtrl_id_o(aluOP), .memToReg_id_o(mToR),
        .regWrite_id_o(rW), .rd_addr_id_o(rd_id),
        .funct3_id_o(funct3_id), 
        .addr_offset_id_o(addr_offset_id),
        // ouput to forward hazard unit
        .rs1_id_o(rs1), .rs2_id_o(rs2),
        .aluSrc_id_o(aluSrc_id), .branch_id_o(branch_id)
    );

    // --- 4. STAGE 3: EXECUTE (EX) ---
    EX ex_stage (
        .clk(clk), .rst(rst), .stall(stall),
        .rs1_val_reg_next(rs1_d), .rs2_imm_reg_next(rs2_id),
        .pc_ex_i(pc_id), .imm_ex_i(imm),
        .aluOP_ex_i(aluOP), .memToReg_ex_i(mToR), .regWrite_ex_i(rW),
        .rd_addr_ex_i(rd_id), 
        .funct3_ex_i(funct3_id), 
        .addr_offset_ex_i(addr_offset_id),
        .aluFwdSrc(aluFwdSrc),
        // Bus Data Input
        .dwb_dat_i(dwb_dat_i), 
        // Result and Feedback
        .res_ex_o(ex_res), .rd_addr_ex_o(rd_wb), .regWrite_ex_o(rW_wb),
        .pc_ex_o(pc_ex), .imm_ex_o(imm_ex), .br_dec_ex_o(br_dec)
    );

    // --- 5. EXTERNAL MEMORY SLAVES  ---
    
    instruction_memory #(.MEM_WORDS(MEM_WORDS)) instr_mem (
        .clk(clk), .rst(rst),
        .wb_adr_i(iwb_adr), .wb_stb_i(iwb_stb),
        .wb_dat_o(iwb_dat), .wb_ack_o(iwb_ack) 
    );

    data_memory #(.MEM_WORDS(MEM_WORDS)) data_mem (
        .clk(clk), .rst(rst),
        .addr(dwb_adr), .Wdata(dwb_dat_o), .sel(dwb_sel),
        .En(dwb_stb && !dwb_we), // En high for Loads
        .We(dwb_stb && dwb_we),  // We high for Stores
        .Rdata(dwb_dat_i), .Ack(dwb_ack)
    );
    
    
    
    ////// Forwarding unit ///////
   forwarding_unit fwd_unit (
        .rW_wb        (rW_wb),
        .dwb_we       (dwb_we),
        .rd_wb        (rd_wb),
        .rs1          (rs1),
        .rs2          (rs2),
        .aluSrc_id    (aluSrc_id), // Connect to ID output
        .branch_id    (branch_id), // Connect to ID output
        .aluFwdSrc    (aluFwdSrc),
        .fwd_mem_data (fwd_mem_data)
    );
endmodule
