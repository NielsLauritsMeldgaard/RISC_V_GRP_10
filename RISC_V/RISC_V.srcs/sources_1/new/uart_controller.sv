module uart_controller (
    input  logic        clk, rst,
    input  logic [7:0]  tx_data_i,   // Byte to send
    input  logic        tx_we_i,     // Start transmission
    output logic [7:0]  rx_data_o,   // Byte received
    output logic        rx_valid_o,  // New data available
    output logic        tx_busy_o,   // UART is currently sending
    output logic        uart_tx_pin, // Physical TX wire
    input  logic        uart_rx_pin  // Physical RX wire
);
    // TODO: Implement Baud-rate generator and Serial FSM
    assign rx_data_o  = 8'h41;       // Constant 'A' for testing reads
    assign rx_valid_o = 1'b0;        // No data yet
    assign tx_busy_o  = 1'b0;        // Never busy for now
    assign uart_tx_pin = 1'b1;       // Idle high
endmodule