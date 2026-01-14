`timescale 1ns / 1ps

module wb_interconnect(
    // --- master interface (from cpu EX stage) --- //
    input  logic [31:0] m_adr_i,
    input  logic [31:0] m_dat_i,
    input  logic [3:0]  m_sel_i,
    input  logic        m_we_i,
    input  logic        m_stb_i,
    output logic [31:0] m_dat_o,
    output logic        m_ack_o,
    
    // --- slave 0: Data ram --- //
    output  logic [31:0] s0_adr_o,
    output logic [31:0] s0_dat_o,
    output logic [3:0]  s0_sel_o,
    output logic        s0_we_o,
    output logic        s0_stb_o,
    input  logic [31:0] s0_dat_i,
    input  logic        s0_ack_i,
    
    // --- slave 1: I/O Peripherals (led, switches, 7seg, uart, ps2) --- // 
        // (connnected to a I/O sub interconect system, VGA will have a seperate slave due to frame buffer)
    output logic [31:0] s1_adr_o,
    output logic [31:0] s1_dat_o,
    output logic [3:0]  s1_sel_o,
    output logic        s1_we_o,
    output logic        s1_stb_o,
    input  logic [31:0] s1_dat_i,
    input  logic        s1_ack_i
    
    // --- slave 2: VGA --- // 
        // (connnected to a I/O sub interconect system, VGA will have a seperate slave due to frame buffer)
//    output logic [31:0] s2_adr_o,
//    output logic [31:0] s2_dat_o,
//    output logic [3:0]  s2_sel_o,
//    output logic        s2_we_o,
//    output logic        s2_stb_o,
//    input  logic [31:0] s2_dat_i,
//    input  logic        s2_ack_i
   
    );
    
    
    
    always_comb begin 
     // Default: All slaves disabled
        s0_stb_o = 1'b0;
        s1_stb_o = 1'b0;
        m_dat_o  = 32'h0;
        m_ack_o  = 1'b0;
    
    // shared bus connections (broadcast from cpu to slaves)
    s0_adr_o = m_adr_i; s0_dat_o = m_dat_i; s0_sel_o = m_sel_i; s0_we_o = m_we_i;
    s1_adr_o = m_adr_i; s1_dat_o = m_dat_i; s1_sel_o = m_sel_i; s1_we_o = m_we_i;
    //s2_adr_o = m_adr_i; s2_dat_o = m_dat_i; s2_we_o = m_we_i; s2_sel_o = m_sel_i;
    case (m_adr_i[31:28])
        
        4'h1: begin // data ram
            s0_stb_o = m_stb_i;
            m_dat_o  = s0_dat_i;
            m_ack_o  = s0_ack_i; 
        end
        
        4'h8: begin // general I/O peripherals
            s1_stb_o = m_stb_i;
            m_dat_o  = s1_dat_i; //send data from IO to CPU
            m_ack_o  = s1_ack_i; // acknowledge from io that data has been recieved to reg, so continue processing
        end
        
//        4'h2: begin // VGA peripherals
//             s2_stb_o = m_stb_i;
//            m_dat_o  = s2_dat_i; //send data from CPU to VGA
//            m_ack_o  = s2_ack_i; // acknowledge from io that data has been recieved to reg, so continue processing
//        end
        default: begin
                // "Bus Error" if CPU accesses invalid address
                m_ack_o = m_stb_i; // Auto-ack to prevent CPU freeze
            end
    
    endcase 
end
    
endmodule
