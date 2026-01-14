`timescale 1ns / 1ps
module debounce (    
    input  logic        clk,
    input  logic        rst,
    input  logic [3:0]  buttons,
    output logic [3:0]  d_buttons
);

    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : debounce_gen
            debounce_single #(
                .n(20)   
            ) debounce_inst (
                .clk      (clk),
                .reset    (rst),
                .sw       (buttons[i]),
                .db_level (d_buttons[i]),
                .db_tick  ()              // intentionally unconnected
            );
        end
    endgenerate

endmodule
