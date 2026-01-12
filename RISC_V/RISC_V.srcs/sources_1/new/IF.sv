module IF_stage #(
    parameter MEM_WORDS = 1024
)(
    input  logic        clk, rst,
    input  logic        pc_sel,        
    input  logic [31:0] pc_from_ex,    
    input  logic [31:0] imm_from_ex,   

    output logic [31:0] pc_wire,      // To be captured by ID
    output logic [31:0] instr_wire    // To be captured by IR in ID
);
    logic [31:0] pc_curr, pc_next;
    logic [31:0] adder_op_a, adder_op_b, adder_out;

    instruction_memory #(.MEM_WORDS(MEM_WORDS)) instr_mem (
        .pc(pc_curr), .instr(instr_wire), .clk(clk)
    );

    always_comb begin 
        adder_op_a = pc_sel ? pc_from_ex  : pc_curr;
        adder_op_b = pc_sel ? imm_from_ex : 4;
        adder_out  = adder_op_a + adder_op_b;
        pc_next    = rst ? 0 : adder_out; 
    end

    always_ff @(posedge clk) begin
        if (rst) pc_curr <= 0;
        else     pc_curr <= pc_next;
    end
    
    assign pc_wire = pc_curr;
endmodule