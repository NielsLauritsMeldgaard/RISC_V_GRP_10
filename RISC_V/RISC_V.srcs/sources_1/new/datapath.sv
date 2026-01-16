module datapath #(
    parameter MEM_WORDS = 1024
)(
    input logic clk, 
    input logic rst,
    
    // --- Physical FPGA I/O Pins ---
    output logic [15:0] leds,
    input  logic [15:0] switches,
    output logic [6:0]  seven_seg_bits,   // Segments A-G + DP
    output logic [3:0]  seven_seg_anodes, // Digit selectors
    input  logic [3:0]  buttons,
    output logic        uart_tx,
    input  logic        uart_rx,
    input  logic        ps2_clk,
    input  logic        ps2_data
) /* synthesis keep_hierarchy=yes */;
    // --- Global Control Signals ---
    logic stall;
    logic br_dec; 
    logic [1:0] aluFwdSrc; 
    logic [4:0] rs1, rs2;
    logic fwd_mem_data;

    // --- CPU Master Instruction Wishbone Bus (I-Bus) ---
    logic [31:0] iwb_adr, iwb_dat;
    logic        iwb_stb, iwb_ack;

    // --- Interconnect Slave Wires for Instruction Memory ---
    // Slave 0: bootloader ROM
    logic [31:0] s0bb_adr, s0bb_dat;
    logic        s0bb_stb, s0bb_ack;
    
    // Slave 1: Instruction RAM    
    logic [31:0] s1im_adr, s1im_dat;
    logic        s1im_stb, s1im_ack;

    // --- CPU Master Data Wishbone (M-Bus) ---
    logic [31:0] dwb_adr, dwb_dat_o, dwb_dat_i;
    logic [3:0]  dwb_sel;
    logic        dwb_we, dwb_stb, dwb_ack;

    // --- Interconnect Slave Wires ---
    // Slave 0: Data RAM
    logic [31:0] s0_adr, s0_dat_w, s0_dat_r;
    logic [3:0]  s0_sel;
    logic        s0_we, s0_stb, s0_ack;

    // Slave 1: IO Subsystem
    logic [31:0] s1_adr, s1_dat_w, s1_dat_r;
    logic [3:0]  s1_sel;
    logic        s1_we, s1_stb, s1_ack;
    
    // Slave 2: instruction ram
    logic [31:0] s2_adr, s2_dat_w, s2_dat_r;
    logic [3:0]  s2_sel;
    logic        s2_we, s2_stb, s2_ack;

    // Slave 2: VGA
//    logic [31:0] s2_adr, s2_dat_w, s2_dat_r;
//    logic [3:0]  s2_sel;
//    logic        s2_we, s2_stb, s2_ack;

    // --- Pipeline Intermediate Wires ---
    logic [31:0] pc_w, instr_w, rs1_d, rs2_id, imm, pc_id, pc_ex, imm_ex, ex_res;
    logic [4:0]  aluOP, rd_id, rd_wb;
    logic [2:0]  funct3_id;
    logic [1:0]  addr_offset_id;
    logic        mToR, rW, rW_wb, aluSrc_id, branch_id;

    // --- 1. GLOBAL STALL LOGIC ---
    //assign stall = (iwb_stb && !iwb_ack) || (dwb_stb && !dwb_ack);
    // iwb_ack is now 1, so we only stall when Data Memory (dwb) is busy
    //assign stall = (1'b1 && !iwb_ack) || ((mToR | dwb_we) && !dwb_ack);
    assign stall = 0;
    
    // Sync rst signal
    logic rst_sync;
    always_ff @(posedge clk)
        rst_sync <= rst;

    // --- 2. STAGE 1: INSTRUCTION FETCH (IF) ---
    IF_stage if_stage (
        .clk(clk), .rst(rst_sync), .stall(stall),
        .pc_sel(br_dec), .pc_from_ex(pc_ex), .imm_from_ex(imm_ex),
        .iwb_adr_o(iwb_adr), .iwb_stb_o(iwb_stb),
        .iwb_dat_i(iwb_dat), .iwb_ack_i(iwb_ack),
        .pc_if_o(pc_w), .instr_if_o(instr_w)
    );

    // --- 3. STAGE 2: INSTRUCTION DECODE (ID) ---
    ID id_stage (
        .clk(clk), .rst(rst_sync), .stall(stall),
        .instr_id_i(instr_w), .pc_id_i(pc_w),
        .rd_data_wb(ex_res), .rd_addr_wb(rd_wb), .regWrite_wb(rW_wb),
        .ex_res(ex_res), .fwd_mem_wdata(fwd_mem_data), .branch_taken(br_dec),
        .dwb_adr_o(dwb_adr), .dwb_dat_o(dwb_dat_o), .dwb_sel_o(dwb_sel),
        .dwb_we_o(dwb_we), .dwb_stb_o(dwb_stb), .dwb_ack_i(dwb_ack),
        .rs1_data_o(rs1_d), .rs2_immData(rs2_id), .imm_id_o(imm),
        .pc_id_o(pc_id), .aluCtrl_id_o(aluOP), .memToReg_id_o(mToR),
        .regWrite_id_o(rW), .rd_addr_id_o(rd_id),
        .funct3_id_o(funct3_id), .addr_offset_id_o(addr_offset_id),
        .rs1_id_o(rs1), .rs2_id_o(rs2),
        .aluSrc2_id_o(aluSrc_id), .branch_id_o(branch_id)
    );

    // --- 4. STAGE 3: EXECUTE (EX) ---
    EX ex_stage (
        .clk(clk), .rst(rst_sync), .stall(stall),
        .rs1_val_reg_next(rs1_d), .rs2_imm_reg_next(rs2_id),
        .pc_ex_i(pc_id), .imm_ex_i(imm),
        .aluOP_ex_i(aluOP), .memToReg_ex_i(mToR), .regWrite_ex_i(rW),
        .rd_addr_ex_i(rd_id), .funct3_ex_i(funct3_id), .addr_offset_ex_i(addr_offset_id),
        .aluFwdSrc(aluFwdSrc), .dwb_dat_i(dwb_dat_i), 
        .res_ex_o(ex_res), .rd_addr_ex_o(rd_wb), .regWrite_ex_o(rW_wb),
        .pc_ex_o(pc_ex), .imm_ex_o(imm_ex), .br_dec_ex_o(br_dec)
    );

    // --- 5. BUS INTERCONNECT ---
    iwb_interconnect iwb_bus_matrix (
        // Master: CPU Instruction Wishbone Bus
        .m_iwb_adr_i(iwb_adr), .m_iwb_stb_i(iwb_stb),
        .m_iwb_dat_o(iwb_dat), .m_iwb_ack_o(iwb_ack),

        // Slave 0: Bootloader ROM
        .s0bb_adr_o(s0bb_adr), .s0bb_stb_o(s0bb_stb),
        .s0bb_dat_i(s0bb_dat), .s0bb_ack_i(s0bb_ack),

        // Slave 1: Instruction RAM
        .s1im_adr_o(s1im_adr), .s1im_stb_o(s1im_stb),
        .s1im_dat_i(s1im_dat), .s1im_ack_i(s1im_ack)
    );
    

    dwb_interconnect dwb_bus_matrix (
        .m_adr_i(dwb_adr), .m_dat_i(dwb_dat_o), .m_sel_i(dwb_sel),
        .m_we_i(dwb_we), .m_stb_i(dwb_stb),
        .m_dat_o(dwb_dat_i), .m_ack_o(dwb_ack),

        // Slave 0: RAM
        .s0_adr_o(s0_adr), .s0_dat_o(s0_dat_w), .s0_sel_o(s0_sel),
        .s0_we_o(s0_we), .s0_stb_o(s0_stb),
        .s0_dat_i(s0_dat_r), .s0_ack_i(s0_ack),

        // Slave 1: IO Manager
        .s1_adr_o(s1_adr), .s1_dat_o(s1_dat_w), .s1_sel_o(s1_sel),
        .s1_we_o(s1_we), .s1_stb_o(s1_stb),
        .s1_dat_i(s1_dat_r), .s1_ack_i(s1_ack),
        
        // Slave 2: IRAM
        .s2_adr_o(s2_adr), .s2_dat_o(s2_dat_w), .s2_sel_o(s2_sel),
        .s2_we_o(s2_we), .s2_stb_o(s2_stb),
        .s2_dat_i(s2_dat_r), .s2_ack_i(s2_ack)
        

        // Slave 2: VGA
//        .s2_adr_o(s2_adr), .s2_dat_o(s2_dat_w), .s2_sel_o(s2_sel),
//        .s2_we_o(s2_we), .s2_stb_o(s2_stb),
//        .s2_dat_i(s2_dat_r), .s2_ack_i(s2_ack)
    );

    // --- 6. SLAVE 1: IO PERIPHERAL MANAGER ---
    io_manager peripherals (
        .clk(clk), .rst(rst_sync),
        // wishbone slave interface (CPU side)
        .wb_adr_i(s1_adr), .wb_dat_i(s1_dat_w), .wb_stb_i(s1_stb),
        .wb_we_i(s1_we), .wb_dat_o(s1_dat_r), .wb_ack_o(s1_ack),
        // Physical Pins
        .leds(leds), .switches(switches), .buttons(buttons),
        .segments(seven_seg_bits), .anodes(seven_seg_anodes),
        .uart_tx(uart_tx), .uart_rx(uart_rx),
        .ps2_clk(ps2_clk), .ps2_data(ps2_data)
    );

    // --- 7. SLAVE 0: DATA RAM ---
    data_memory #(.MEM_WORDS(MEM_WORDS)) data_mem (
        .clk(clk), .rst(rst_sync),
        .addr(s0_adr), .Wdata(s0_dat_w), .sel(s0_sel),
        .En(s0_stb && !s0_we), .We(s0_stb && s0_we),
        .Rdata(s0_dat_r), .Ack(s0_ack)
    );

    // --- 8. INSTRUCTION MEMORY (Dual-Port) ---
    instruction_memory #(.MEM_WORDS(MEM_WORDS)) instr_mem (
        .clk(clk), .rst(rst_sync),
        // PORT A: Write from Data WB (Bootloader writes via slave 2)
        .a_dwb_adr_i(s2_adr), .a_dwb_dat_i(s2_dat_w), .a_dwb_sel_i(s2_sel),
        .a_dwb_we_i(s2_we), .a_dwb_stb_i(s2_stb),
        .a_dwb_dat_o(), .a_dwb_ack_o(s2_ack),
        // PORT B: Read from Instr WB (CPU instruction fetch via slave 1)
        .b_iwb_adr_i(s1im_adr), .b_iwb_stb_i(s1im_stb),
        .b_iwb_dat_o(s1im_dat), .b_iwb_ack_o(s1im_ack)
    );
    
    // --- 9. I-WB SLAVE 0: BOOTLOADER ROM ---
    brom bootloader (
        .clk(clk), .rst(rst_sync),
        .wb_adr_i(s0bb_adr), .wb_stb_i(s0bb_stb),
        .wb_dat_o(s0bb_dat), .wb_ack_o(s0bb_ack)
    );

    // Slave 2 Placeholder (VGA)
    //assign s2_ack_i = s2_stb_o; 
    //assign s2_dat_i = 32'h0;

    // --- 9. FORWARDING UNIT ---
    forwarding_unit fwd_unit (
        .rW_wb(rW_wb), .dwb_we(dwb_we), .rd_wb(rd_wb),
        .rs1(rs1), .rs2(rs2), .aluSrc_id(aluSrc_id),
        .branch_id(branch_id), .aluFwdSrc(aluFwdSrc),
        .fwd_mem_data(fwd_mem_data)
    );

endmodule