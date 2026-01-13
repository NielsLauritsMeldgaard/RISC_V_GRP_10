`timescale 1ns / 1ps

// The first pipeline stage is contained withing this module. The output of the sync. mem has a output reg. and PC is also sequentiel.
// The "Next Input Value (pc_next)" is used as the IM address, thus ensuring pipeline register alignment!!
 
module if_stage #(
        parameter int INSTR_MEM_SIZE = 8,
        parameter string FILE_NAME = "rom.mem"
    )(
        input logic clk,
        input logic rst,
        input logic CPURun,
        input logic addSel,
        input logic [31:0] pc_offset,
        input logic [31:0] pc_ex,
        output logic [31:0] instr,
        output logic [31:0] pc_id_next
    );
                
        logic [$clog2(INSTR_MEM_SIZE * 4) - 1 : 0] pc, pc_next; // The width should be four times greater to make up for bytewise offset (0, 4, 8... N * 4)     
        logic [$clog2(INSTR_MEM_SIZE - 1) : 0] rom_addr;  
        logic [31:0] addSrc1, addSrc2;     
        
        // Init the instruction memory
        sync_rom #(
            .MEM_SIZE_WORDS(INSTR_MEM_SIZE),
            .FILE_NAME(FILE_NAME)
        ) IM (
            .clk(clk),
            .addr(rom_addr), // The BRAM takes chronological address from .mem file (0, 1, 2... N)
            .dout(instr)
        );
        
        always_comb begin
            pc_id_next = pc;
            if (CPURun) begin
                addSrc1 = (addSel ? pc_ex : pc);
                addSrc2 = (addSel ? pc_offset : 4);                
                pc_next = addSrc1 + addSrc2;
            end else
                pc_next = pc;                        
            //pc_next = CPURun ? 4 + pc : pc; // Increment PC if the run flag is high
            rom_addr = pc_next >> 2; //@TODO: This starts at #4 not #0
        end
        
        // sync resets
        always_ff @(posedge clk) begin
            if (rst) begin
                pc <= 0;
            end else begin
                pc <= pc_next;
            end
        end           
        
endmodule


//module if_stage #(
//        parameter int INSTR_MEM_SIZE = 8,
//        parameter string FILE_NAME = "rom.mem"
//    )(
//        input logic clk,
//        input logic rst,
//        //@TODO: perhaps rename
//        input logic mux_sel,
//        input logic [31:0] pc_offset,
//        output logic [31:0] instr_IF
//    );
                
//        logic [$clog2(INSTR_MEM_SIZE * 4) - 1 : 0] pc, pc_next; // The width should be four times greater to make up for bytewise offset (0, 4, 8... N * 4)     
//        logic [31:0] mux_out;
//        logic [$clog2(INSTR_MEM_SIZE - 1) : 0] rom_addr;       
        
//        // Init the instruction memory
//        sync_rom #(
//            .MEM_SIZE_WORDS(INSTR_MEM_SIZE),
//            .FILE_NAME(FILE_NAME)
//        ) IM (
//            .clk(clk),
//            .addr(rom_addr), // The BRAM takes chronological address from .mem file (0, 1, 2... N)
//            .dout(instr_IF)
//        );
        
//        always_comb begin
//            // select between the offset computed from the ALU or the standard 4
//            mux_out = (mux_sel ? pc_offset : 4);
//            pc_next = mux_out + pc;
//            rom_addr = pc_next >> 2; //@TODO: This starts at #4 not #0
//        end
        
//        // sync resets
//        always_ff @(posedge clk) begin
//            if (rst) begin
//                pc <= 0;
//            end else begin
//                pc <= pc_next;
//            end
//        end           
        
//endmodule
