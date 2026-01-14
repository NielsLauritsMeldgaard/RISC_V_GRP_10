`timescale 1ns / 1ps

module IF_stage #(
    parameter MEM_WORDS = 1024
)(
    input  logic        clk,
    input  logic        rst,
    input  logic        stall,         // stall: stops registers when waiting for memory
    
    // --- Branch/Jump Logic (Feedback from EX) ---
    input  logic        pc_sel,        // PC_select: high if branch taken; add PC from EX + imm from EX
    input  logic [31:0] pc_from_ex,    // PC from execute stage: pipelined back to match branch calc.,
    input  logic [31:0] imm_from_ex,   // immidiate value from EX stage: pipelined back

    // --- Instruction Wishbone Master --- Harvard style with seperate instructions and data BUS 
    output logic [31:0] iwb_adr_o,     // Address to Bus
    output logic        iwb_stb_o,     // Strobe/Request to Bus
    input  logic [31:0] iwb_dat_i,     // Instruction from Bus
    input  logic        iwb_ack_i,     // Acknowledge from Bus

    // --- Pipeline Outputs to ID Stage ---
    output logic [31:0] pc_if_o,       // Current PC in instruction fetch stage output
    output logic [31:0] instr_if_o     // instruction bits from IF stage output
);

    logic [31:0] pc_curr, pc_next;
    logic [31:0] adder_op_a, adder_op_b, adder_out;  // PC adder I/O

    // --- 1. OPERATOR SHARING ADDER ---
    // Calculates either PC+4 (Normal) or Branch-Target (pc_ex + imm_ex)
    always_comb begin 
        adder_op_a = pc_sel ? pc_from_ex  : pc_curr;
        adder_op_b = pc_sel ? imm_from_ex : 32'd4;
        adder_out  = adder_op_a + adder_op_b;
        
        pc_next    = rst ? 32'h0 : adder_out; 
    end

    // --- 2. THE PC REGISTER ---
    // Freezes state if the 'stall' signal is high
    always_ff @(posedge clk) begin
        if (rst) begin
            pc_curr <= 32'h0;
        end else if (!stall) begin
            pc_curr <= pc_next;
        end
        // If stall is high, pc_curr retains its previous value
    end
    
    // --- 3. WISHBONE BUS ASSIGNMENTS ---
    assign iwb_adr_o  = pc_curr;
    assign iwb_stb_o  = 1'b1;         // Always requesting instructions
    
    // --- 4. OUTPUTS TO ID STAGE ---
    assign pc_if_o    = pc_curr;      // PC to be captured in pc_id register
    assign instr_if_o = iwb_dat_i;    // Bits to be captured in IR register

endmodule
