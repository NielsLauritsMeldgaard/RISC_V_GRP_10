`timescale 1ns / 1ps

module ALU(
    input  logic [31:0] op1,
    input  logic [31:0] op2,
    input  logic [4:0]  aluOP, // MUST be 5 bits
    output logic [31:0] res
    );

    always_comb begin
        res = 32'b0; // Default output

        casez (aluOP) // casez is required for the '?' wildcards
            // Arithmetic / logic
            5'b00000: res = op1 + op2;                           // ADD
            5'b00001: res = op1 - op2;                           // SUB
            5'b01000: res = op1 ^ op2;                           // XOR
            5'b01100: res = op1 | op2;                           // OR
            5'b01110: res = op1 & op2;                           // AND

            // Shifts
            5'b00010: res = op1 << op2[4:0];                     // SLL
            5'b01010: res = op1 >> op2[4:0];                     // SRL
            5'b01011: res = $signed(op1) >>> op2[4:0];           // SRA

            // Set comparisons
            5'b00100: res = ($signed(op1) < $signed(op2)) ? 32'd1 : 32'd0; // SLT
            5'b00110: res = (op1 < op2) ? 32'd1 : 32'd0;                  // SLTU

            // -------- Branch conditions --------
            // If condition is true, return 1, else 0
            5'b1000?: res = (op1 == op2) ? 32'd1 : 32'd0;         // BEQ
            5'b1001?: res = (op1 != op2) ? 32'd1 : 32'd0;         // BNE
            5'b1100?: res = ($signed(op1) < $signed(op2)) ? 32'd1 : 32'd0; // BLT
            5'b1101?: res = ($signed(op1) >= $signed(op2)) ? 32'd1 : 32'd0;// BGE
            5'b1110?: res = (op1 < op2) ? 32'd1 : 32'd0;          // BLTU
            5'b1111?: res = (op1 >= op2) ? 32'd1 : 32'd0;         // BGEU

            default: res = 32'b0;
        endcase
    end
endmodule