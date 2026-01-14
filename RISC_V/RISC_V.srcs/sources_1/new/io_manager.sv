`timescale 1ns / 1ps

module io_manager (
    input  logic        clk, rst,
    // --- Wishbone Slave Interface (CPU Side) ---
    input  logic [31:0] wb_adr_i,   // Address
    input  logic [31:0] wb_dat_i,   // Data from CPU
    input  logic        wb_stb_i,   // Request
    input  logic        wb_we_i,    // Write Enable
    output logic [31:0] wb_dat_o,   // Data to CPU
    output logic        wb_ack_o,   // Ready

    // --- Physical FPGA Pins ---
    output logic [15:0] leds,
    input  logic [15:0] switches,
    output logic [7:0]  segments,
    output logic [3:0]  anodes,
    input  logic [4:0]  buttons,
    output logic        uart_tx,
    input  logic        uart_rx,
    input  logic        ps2_clk, ps2_data
);
    // --- Internal Wires ---
    logic [1:0] word_index;
    logic       write_stb;
    logic       seg_we, uart_we;
    logic [7:0] u_rx_data, p_key_data;
    logic       u_rx_valid, u_tx_busy, p_ready;

     always_comb begin 
        case word_index 
            2'b00: begin
            
            end
            2'b01: begin
            
            end
            2'b10: begin
            
            end
            2'b11: begin 
            
            end        
        end 
     end 
     
     always_ff begin 
     
     
     end
    // --- 3. SUB-MODULE INSTANTIATIONS ---

    seven_seg_controller seg_unit (
        .clk(clk), .rst(rst),
        .data_i(wb_dat_i), .we(seg_we),
        .segments(segments), .anodes(anodes)
    );

    uart_controller uart_unit (
        .clk(clk), .rst(rst),
        .tx_data_i(wb_dat_i[7:0]), .tx_we_i(uart_we),
        .rx_data_o(u_rx_data), .rx_valid_o(u_rx_valid), .tx_busy_o(u_tx_busy),
        .uart_tx_pin(uart_tx), .uart_rx_pin(uart_rx)
    );

    ps2_controller ps2_unit (
        .clk(clk), .rst(rst),
        .ps2_clk(ps2_clk), .ps2_data(ps2_data),
        .key_code_o(p_key_data), .data_ready_o(p_ready)
    );

endmodule