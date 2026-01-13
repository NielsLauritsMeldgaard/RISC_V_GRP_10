`timescale 1ns / 1ps

module data_memory #(
    parameter MEM_WORDS = 1024 
)(
    input  logic         clk,
    input  logic         rst,        // Global reset
    input  logic [31:0]  addr,       // Byte address from CPU
    input  logic [31:0]  Wdata,      // Data to store
    input  logic [3:0]   sel,        // Byte select mask (Wishbone SEL)
    input  logic         En,         // Strobe for Read (memRead)
    input  logic         We,         // Strobe for Write (memWrite)
    output logic [31:0]  Rdata,      // Data to load
    output logic         Ack         // Wishbone Acknowledge
);
    // Force Block RAM inference
    (* ram_style = "block" *) 
    logic [31:0] mem [0:MEM_WORDS-1];

    // Initialize memory to zero
    initial begin
        for (int i = 0; i < MEM_WORDS; i++) begin
            mem[i] = 32'h0;
        end
    end

    // --- Synchronous Logic Block ---
    always_ff @(posedge clk) begin
        if (rst) begin
            Rdata <= 32'h0;
            Ack   <= 1'b0;
        end else begin
            // 1. Handshake Logic
            // Ack goes high 1 cycle after a request (En or We)
            // We use '!Ack' to ensure it's a 1-cycle pulse per request
            Ack <= (En | We) && !Ack;

            // 2. Read Logic
            if (En) begin
                Rdata <= mem[addr >> 2];
            end

            // 3. Write Logic (Byte-Selective)
            // Note: We is outside 'if (En)' to support 'We-only' write cycles
            if (We) begin
                if (sel[0]) mem[addr >> 2][7:0]   <= Wdata[7:0];
                if (sel[1]) mem[addr >> 2][15:8]  <= Wdata[15:8];
                if (sel[2]) mem[addr >> 2][23:16] <= Wdata[23:16];
                if (sel[3]) mem[addr >> 2][31:24] <= Wdata[31:24];
            end
        end
   end
endmodule