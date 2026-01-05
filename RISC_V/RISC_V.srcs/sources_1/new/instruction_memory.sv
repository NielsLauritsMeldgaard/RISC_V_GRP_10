`timescale 1ns / 1ps
module sync_rom #(
        parameter int MEM_SIZE_WORDS = 8,
        parameter string FILE_NAME = "rom.mem" 
    )(
        input clk,
        input logic [$clog2(MEM_SIZE_WORDS) - 1 : 0] addr,
        output logic [31 : 0] dout
    );
    
    (* ram_style = "block" *)
    logic signed [31:0] rom [0:MEM_SIZE_WORDS-1];

    initial begin
        $readmemh(FILE_NAME, rom);
    end

    always_ff @(posedge clk) begin
        dout <= rom[addr];
    end
    
endmodule