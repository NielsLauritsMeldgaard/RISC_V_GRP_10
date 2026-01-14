module seven_seg_controller (
    input  logic        clk, rst,
    input  logic [31:0] data_i,    // 32-bit data from CPU (e.g., 4x8-bit hex codes)
    input  logic        we,        // Write enable from io_manager
    output logic [7:0]  segments,  // Physical pins: A, B, C, D, E, F, G, DP
    output logic [3:0]  anodes     // Physical pins: Digit selector
);
    // Placeholder for internal register
    logic [31:0] display_reg;

    always_ff @(posedge clk) begin
        if (rst) display_reg <= 32'h0;
        else if (we) display_reg <= data_i;
    end

    // TODO: Implement multiplexing logic here to drive segments/anodes
    assign segments = 8'hFF; // All off
    assign anodes   = 4'hF;   // All off
endmodule