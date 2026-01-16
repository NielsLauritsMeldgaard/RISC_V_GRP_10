`timescale 1ns / 1ps

module brom #(
    //@TODO: Write bootloader program and find correct program size
    parameter MEM_WORDS = 128, // 128 instructions
    //parameter BOOTROM_FILE = "../../../../tests/task1/addpos.mem"
    parameter BOOTROM_FILE = "../../../../bootloader/bootloader.mem"
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
        $readmemh(BOOTROM_FILE, mem);
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

