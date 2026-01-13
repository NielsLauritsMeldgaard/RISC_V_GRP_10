`timescale 1ns / 1ps

module instruction_memory #(
    parameter MEM_WORDS = 1024             
)(
    input  logic         clk,
    input  logic         rst,              // reset for handshake logic
    
    // --- Wishbone Slave Interface ---
    input  logic [31:0]  wb_adr_i,         // PC from IF_stage
    input  logic         wb_stb_i,         // Strobe (Request) from IF_stage
    output logic [31:0]  wb_dat_o,         // Instruction bits to IF_stage
    output logic         wb_ack_o          // Acknowledge (Ready) to IF_stage
);

    // Force Block RAM inference
    (* rom_style = "block" *) 
    logic [31:0] mem [0:MEM_WORDS-1];
    
    // Load the program
    initial begin
        $readmemh("C:/Users/amads/02144_riscV/RISC_V_GRP_10/RISC_V/RISC_V.srcs/sim_1/new/program.hex", mem);
    end

    // --- Synchronous Logic ---
    always_ff @(posedge clk) begin
        if (rst) begin
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'h0;
        end else begin
           
            wb_ack_o <= wb_stb_i && !wb_ack_o;

            
            if (wb_stb_i) begin
                wb_dat_o <= mem[wb_adr_i >> 2];
            end
        end
    end

endmodule