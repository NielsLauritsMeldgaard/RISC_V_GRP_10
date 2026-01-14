`timescale 1ns / 1ps

module instruction_memory #(
    parameter MEM_WORDS = 32768 // 128KB             
)(
    input  logic         clk,
    input  logic         rst,              
    
    // --- Wishbone Slave Interface ---
    input  logic [31:0]  wb_adr_i,         // Byte Address (PC)
    input  logic         wb_stb_i,         // Strobe (Request)
    output logic [31:0]  wb_dat_o,         // Instruction Data
    output logic         wb_ack_o          // Acknowledge (Ready)
);

    // Calculate bits needed for indexing
    // 32768 words -> 15 bits. Byte address bits [16:2]
    localparam ADDR_BITS = $clog2(MEM_WORDS);

    // Force Block RAM inference
    (* rom_style = "block" *) 
    logic [31:0] mem [0:MEM_WORDS-1];
    
    
    initial begin
      
        $readmemh("C:/Users/amads/02144_riscV/RISC_V_GRP_10/RISC_V/RISC_V.srcs/sim_1/new/program.hex", mem);
    end

    // --- Synchronous Logic ---
    always_ff @(posedge clk) begin
        if (rst) begin
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'h00000013; 
        end else begin
            
            wb_ack_o <= wb_stb_i && !wb_ack_o;

          
            if (wb_stb_i) begin
               
                wb_dat_o <= mem[wb_adr_i[ADDR_BITS+1 : 2]];
            end
        end
    end

endmodule
