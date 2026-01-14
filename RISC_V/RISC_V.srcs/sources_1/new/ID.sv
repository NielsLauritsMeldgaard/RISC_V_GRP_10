`timescale 1ns / 1ps

module ID(
    // --- Global Control Signals ---
    input  logic        clk,               // System clock
    input  logic        rst,               // Global synchronous reset
    input  logic        stall,             // From datapath: Freezes IR/PC when memory is busy
    input  logic        branch_taken,      // From EX: High if a branch is taken (flushes IR to NOP)

    // --- Inputs from IF Stage (Combinational Wires) ---
    input  logic [31:0] instr_id_i,          // Raw instruction bits from instruction memory
    input  logic [31:0] pc_id_i,             // PC address of the current instruction_in from IF

    // --- Feedback from EX Stage (Write-Back) ---
    input  logic [31:0] rd_data_wb,        // Final result to be written into the Register File
    input  logic [4:0]  rd_addr_wb,        // Destination register address for Write-Back
    input  logic        regWrite_wb,       // Write-enable signal for the Register File
    input  logic [31:0] ex_res,            // Current cycle result (used for internal forwarding)- from Execute stage
    
    // --- I/O for Forwarding Control ---
    input  logic        fwd_mem_wdata,     // Logic to decide if ex_res should be forwarded to Store
    output logic        aluSrc_id_o,
    output logic        branch_id_o,
    output logic [4:0]  rs1_id_o,             // source register 1: used only for forward hazard unit
    output logic [4:0]  rs2_id_o,             // source register 2: used only for forward hazard unit 
  

    // --- Data Wishbone Master Interface (To Data Memory/Cache) ---
    output logic [31:0] dwb_adr_o,         // Memory address (calculated as rs1 + imm)
    output logic [31:0] dwb_dat_o,         // Data to be stored (shifted into correct byte lane)
    output logic [3:0]  dwb_sel_o,         // Byte select mask (for sb,sh, sw in data mem); 4'b1111 -> sw, 4'b0001 sb (byte 0), etc.
    output logic        dwb_we_o,          // Write enable (1 for Store, 0 for Load)
    output logic        dwb_stb_o,         // Strobe: Initiates a memory request
    output logic        dwb_cyc_o,         // Cycle: High for the duration of the bus transaction
    input  logic        dwb_ack_i,         // Acknowledge: Memory has finished the request

    // --- Pipeline Outputs to EX Stage ---
    output logic [31:0] rs1_data,          // Data from source register 1
    output logic [31:0] rs2_immData,       // Muxed operand 2 (either rs2_data or immediate)
    output logic [31:0] imm_id_o,          // Sign-extended 32-bit immediate value
   
    
    output logic [31:0] pc_id_o,          // Pipelined PC value sent to EX for branch math
    output logic [4:0]  aluCtrl_id_o,     // ALU control opcode sent to EX
    output logic        memToReg_id_o,    // Control: Select memory result for Write-Back
    
    output logic        regWrite_id_o,    // Control: Enables Register File write-back
    output logic [4:0]  rd_addr_id_o,     // Pipelined destination register address
    output logic [2:0]  funct3_id_o,      // instr[14:12] needed in EX for Load slicing
    output logic [1:0]  addr_offset_id_o  // Last 2 bits of address needed in EX for Load slicing
    );

    // --- Internal Typedefs and Logic ---
    typedef enum logic [2:0] { IMM_I, IMM_S, IMM_B, IMM_U, IMM_J } imm_sel_t;   // immidiate types

    logic [6:0]  opcode;                   // Extracted opcode from IR
    logic [4:0]  rs1, rs2, rd;             // Extracted register addresses from IR
    logic aluSrc, memToReg, regWrite, memWrite, branch; // Control flags
    logic [4:0] aluCtrl;                   // Combinational ALU opcode
    logic [2:0] imm_sel;                   // Selector for immediate generation type
    logic [31:0] rs2_data;                 // Raw data from source register 2
    logic [31:0] IR_next;                  // Combinational next state of the IR
    logic [31:0] Dmem_data;                // data for data memory from rs2
    // --- PIPELINE REGISTERS (IR and PC) ---
    logic [31:0] IR, pc_id;                // The Instruction Register and associated PC
    
    always_ff @(posedge clk) begin
        if (rst) begin
            IR    <= 32'h00000013;         // Reset to ADDI x0, x0, 0 (NOP)
            pc_id <= 0;
        end else if (!stall) begin         // Capture logic: Only update if not stalling
            IR    <= IR_next;
            pc_id <= pc_id_i;
        end
    end

    // --- Register File Instance ---
    regFile regFile (
     .clk(clk), .rst(rst), .we(regWrite_wb),         
     .rs1_addr(IR[19:15]), .rs2_addr(IR[24:20]),   
     .rd_addr(rd_addr_wb), .rd_data(rd_data_wb),    
     .rs1_data(rs1_data), .rs2_data(rs2_data) 
    );

    // --- Main Decoder and Data Logic ---
    always_comb begin
         // 1. Flush Logic
         IR_next =  branch_taken ? 32'h00000013 : instr_id_i;  // flush with NOP, if branch taken

         // 2. IR Partitioning
         rs1    = IR[19:15];
         rs2    = IR[24:20];
         rd     = IR[11:7];
         opcode = IR[6:0];
         
         rs1_id_o = rs1;
         rs2_id_o = rs2;
        
         
         // 3. Decoder Defaults
         aluSrc = 0; memToReg = 0; regWrite = 0; memWrite = 0; branch = 0; 
         aluCtrl = 5'b0; imm_sel = IMM_I; 

         // 4. Instruction Opcode Table
         case (opcode)
            7'b0110011: begin regWrite = 1; aluCtrl = {1'b0,IR[14:12],IR[30]}; end
            7'b0010011: begin aluSrc = 1; regWrite = 1; aluCtrl = {1'b0,IR[14:12],1'b0}; end
            7'b0000011: begin aluSrc = 1; memToReg = 1; regWrite = 1; end
            7'b0100011: begin aluSrc = 1; memWrite = 1; imm_sel = IMM_S; end
            7'b1100011: begin branch = 1; aluCtrl = {1'b1,IR[14:12],1'b0}; imm_sel = IMM_B; end
            default: ;    
         endcase

         // 5. Immediate Generation
         case (imm_sel)
             IMM_I: imm_id_o = {{20{IR[31]}}, IR[31:20]};
             IMM_S: imm_id_o = {{20{IR[31]}}, IR[31:25], IR[11:7]};
             IMM_B: imm_id_o = {{19{IR[31]}}, IR[31], IR[7], IR[30:25], IR[11:8], 1'b0};
             default: imm_id_o = 32'b0;
         endcase
         
         // 6. Output Signal Driving
         pc_id_o         = pc_id;
         aluCtrl_id_o  = aluCtrl;
         memToReg_id_o = memToReg;
       
         
         regWrite_id_o = regWrite;
         rd_addr_id_o  = rd;
         funct3_id_o   = IR[14:12];
         addr_offset_id_o = dwb_adr_o[1:0];
         
         rs2_immData = aluSrc ? imm_id_o : rs2_data; 
         dwb_adr_o   = rs1_data + imm_id_o; 
         
         aluSrc_id_o = aluSrc;
         branch_id_o = branch;
         
    end
    
    // --- Data Wishbone Control Logic ---
    always_comb begin
        // A. Byte Select Logic (Masking)
        case (IR[14:12]) 
            3'b000: dwb_sel_o = 4'b0001 << dwb_adr_o[1:0];       // Byte (SB/LB)
            3'b001: dwb_sel_o = dwb_adr_o[1] ? 4'b1100 : 4'b0011; // Half (SH/LH)
            default: dwb_sel_o = 4'b1111;                         // Word (SW/LW)
        endcase
    
        // B. Wishbone Handshake Logic
        dwb_we_o  = memWrite; 
        dwb_stb_o = (memToReg | memWrite);
        dwb_cyc_o = dwb_stb_o;
        
        // C. Data Alignment for Stores
       
        
        case (IR[14:12])
            3'b000: Dmem_data = {4{rs2_data[7:0]}};  // Replicate byte across word
            3'b001: Dmem_data = {2{rs2_data[15:0]}}; // Replicate half across word
            default: Dmem_data = rs2_data;           // Full word
        endcase
        
        dwb_dat_o = fwd_mem_wdata ? ex_res : Dmem_data;
    end
        
endmodule
