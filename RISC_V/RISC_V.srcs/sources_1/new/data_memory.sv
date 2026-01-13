`timescale 1ns / 1ps

module sync_ram_byte_en #(
    parameter int MEM_SIZE_WORDS = 128          // total words
)(
    input  logic         clk,
    input  logic         wrEn,                  // write enable
    input  logic [3:0]   be,                    // byte enable
    input  logic [31:0]  addr,                  // byte address
    input  logic [31:0]  din,                   // write data
    output logic [31:0]  dout                   // read data (registered)
);
    // inferred block RAM with byte write enables
    (* ram_style = "block" *)
    logic [7:0] b0 [0:MEM_SIZE_WORDS-1];
    logic [7:0] b1 [0:MEM_SIZE_WORDS-1];
    logic [7:0] b2 [0:MEM_SIZE_WORDS-1];
    logic [7:0] b3 [0:MEM_SIZE_WORDS-1];

    always_ff @(posedge clk) begin
        // Writes: respect byte enables
        if (wrEn) begin
            if (be[0]) b0[addr[31:2]] <= din[7:0];
            if (be[1]) b1[addr[31:2]] <= din[15:8];
            if (be[2]) b2[addr[31:2]] <= din[23:16];
            if (be[3]) b3[addr[31:2]] <= din[31:24];
        end
        // Reads: always read all bytes (byte enables handled by load logic)
        dout[7:0]   <= b0[addr[31:2]];
        dout[15:8]  <= b1[addr[31:2]];
        dout[23:16] <= b2[addr[31:2]];
        dout[31:24] <= b3[addr[31:2]];
    end
    

endmodule