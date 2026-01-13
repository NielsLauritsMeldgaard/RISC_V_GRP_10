`timescale 1ns / 1ps
import types_pkg::*;


module datapath(
        input logic clk,
        input logic rst,
        output logic CPURun_out,
        output logic [31:0] a0_value_out
    );
    
    //logic [31:0] a0_value_out;
//    logic led;
//    assign led = a0_value_out[0];
    
    
    localparam int INSTR_MEM_SIZE = 32;
    localparam string FILE_NAME = "rom.mem";
    
    logic [31:0] instr_if, ALUSrc1_next, ALUSrc2_next, ALUSrc1, ALUSrc2, ALU_result, pc_offset, pc_offset_next;
    logic [31:0] pc_id, pc_id_next, pc_ex, pc_ex_next;
    logic wr_en_next, wr_en, CPURun_next, CPURun, branch, branch_next, branch_taken;
    logic [3:0] ALUOp_next, ALUOp;
    logic [4:0] wr_idx_next, wr_idx;
    logic mem_wrEn, mem_rdEn, mem_to_reg_next, mem_to_reg;
    logic [3:0] mem_be; // byte enable datamem
    logic [31:0] mem_din, mem_dout, mem_addr, mem_load_data, reg_writeback_data;
    logic [2:0] mem_funct3_next, mem_funct3;
    
    assign pc_ex_next = pc_id;  
    
    if_stage #(
        .INSTR_MEM_SIZE(INSTR_MEM_SIZE),
        .FILE_NAME(FILE_NAME)
    ) if_stage_u (
        .clk(clk),
        .rst(rst),        
        .instr(instr_if),
        .CPURun(CPURun),
        .pc_offset(pc_offset),
        .addSel(branch_taken),
        .pc_id_next(pc_id_next),
        .pc_ex(pc_ex)       
    );
    
    id_stage id_stage_u(
        .clk(clk),
        .rst(rst),
        .wr_idx(wr_idx),
        .wr_en(wr_en),
        .instr_if(instr_if),
        .reg_din(reg_writeback_data),
        .flush(branch_taken),
        .ALUSrc1_next(ALUSrc1_next),
        .ALUSrc2_next(ALUSrc2_next),
        .wr_en_next(wr_en_next),
        .ALUOp_next(ALUOp_next),
        .wr_idx_next(wr_idx_next),
        .CPURun_next(CPURun_next),
        .a0_value_out(a0_value_out),
        .branch_next(branch_next),
        .pc_offset_next(pc_offset_next),
        .mem_byte_en(mem_be),
        .mem_wr_en(mem_wrEn),
        //.mem_rd_en(mem_rdEn),
        .mem_addr(mem_addr),
        .mem_dataWr(mem_din),
        .mem_funct3_next(mem_funct3_next),
        .mem_to_reg_next(mem_to_reg_next)
    );
    
    ex_stage ex_stage_u (
        .clk(clk),
        .rst(rst),
        .ALUSrc1(ALUSrc1),
        .ALUSrc2(ALUSrc2),
        .ALUOp(ALUOp),
        .result(ALU_result)   
    );
    
    sync_ram_byte_en #(
        .MEM_SIZE_WORDS(128)
    ) data_mem_u (
        .clk(clk),
        .wrEn(mem_wrEn),
        .be(mem_be),
        .addr(mem_addr),
        .din(mem_din),
        .dout(mem_dout)    
    );
    
    assign branch_taken = branch && ALU_result;
    
    // Load data processing with sign extension
    always_comb begin
        case (mem_funct3)
            3'h0: begin // LB: load byte (sign-extended)
                mem_load_data = {{24{mem_dout[7]}}, mem_dout[7:0]};
            end
            3'h1: begin // LH: load halfword (sign-extended)
                mem_load_data = {{16{mem_dout[15]}}, mem_dout[15:0]};
            end
            3'h2: begin // LW: load word
                mem_load_data = mem_dout;
            end
            3'h4: begin // LBU: load byte (zero-extended)
                mem_load_data = {24'b0, mem_dout[7:0]};
            end
            3'h5: begin // LHU: load halfword (zero-extended)
                mem_load_data = {16'b0, mem_dout[15:0]};
            end
            default: mem_load_data = mem_dout;
        endcase
    end
    
    // Writeback mux: select between ALU result and memory data
    assign reg_writeback_data = mem_to_reg ? mem_load_data : ALU_result;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ALUSrc1 <= 0;
            ALUSrc2 <= 0;
            wr_en <= 0;
            wr_idx <= 0;
            ALUOp <= 0;
            CPURun <= 1;
            pc_offset <= 0;
            branch <= 0;
            pc_id <= 0;
            pc_ex <= 0;
            mem_to_reg <= 0;
            mem_funct3 <= 0;
        end else begin
            ALUSrc1 <= ALUSrc1_next;
            ALUSrc2 <= ALUSrc2_next;
            wr_en <= wr_en_next;
            wr_idx <= wr_idx_next;
            ALUOp <= ALUOp_next;
            CPURun <= CPURun & CPURun_next; // latch low until reset
            pc_offset <= pc_offset_next;
            branch <= branch_next;
            pc_id <= pc_id_next;
            pc_ex <= pc_ex_next;
            mem_to_reg <= mem_to_reg_next;
            mem_funct3 <= mem_funct3_next;
        end        
    end
    
        // Expose CPURun to the testbench
        assign CPURun_out = CPURun;
    

endmodule
