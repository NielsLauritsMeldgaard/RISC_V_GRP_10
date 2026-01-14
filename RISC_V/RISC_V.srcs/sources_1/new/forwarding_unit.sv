`timescale 1ns / 1ps

module forwarding_unit (
    // Inputs
    input  logic        rW_wb,        // writeback register write enable
    input  logic        dwb_we,       // data writeback enable (for stores)
    input  logic        aluSrc_id,    // High if instruction uses an Immediate (I-type)
    input  logic        branch_id,    // High if instruction is a Branch
    input  logic [4:0]  rd_wb,        // destination register 
    input  logic [4:0]  rs1,          // source register 1 
    input  logic [4:0]  rs2,          // source register 2 

    // Outputs
    output logic [1:0]  aluFwdSrc,     // [1]=rs1 forward, [0]=rs2 forward
    output logic        fwd_mem_data   // forward data to memory store
);

    always_comb begin
        // defaults
        aluFwdSrc    = 2'b00;
        fwd_mem_data = 1'b0;

        ////// EXECUTE STAGE HAZARDS //////

        // Forward to ALU operand A (rs1)
        if (rW_wb && (rd_wb != 5'd0) && (rd_wb == rs1)) begin
            aluFwdSrc[1] = 1'b1;
        end

        // Forward to ALU operand B (rs2)
        // CRITICAL FIX: Only forward to Op2 if the instruction 
        // is NOT using an immediate (aluSrc is 0) OR if it is a Branch.
        if (rW_wb && (rd_wb != 5'd0) && (rd_wb == rs2)) begin
            if (!aluSrc_id || branch_id) begin
                aluFwdSrc[0] = 1'b1;
            end
        end

        ////// MEMORY STORE HAZARD //////

        // Forward store data from WB stage
        if (rW_wb && dwb_we && (rd_wb != 5'd0) && (rd_wb == rs2)) begin
            fwd_mem_data = 1'b1;
        end
    end

endmodule
