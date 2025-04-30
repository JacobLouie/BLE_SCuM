`timescale 1ns / 1ps
module Packet_Sniffer (
    clk, symbol_clk, rst, en, symbol_in,
    packet_detected, packet_out, packet_len,
    acc_addr, channel
);
    parameter PACKET_LEN_MAX = 376;
    parameter PREAMBLE_LEN = 8;
    parameter ACC_ADDR_LEN = 32;
    parameter CRC_POLY = 24'h00065B;
    parameter CRC_INIT = 24'h555555;

    input wire clk, symbol_clk, rst, en, symbol_in;
    input wire [ACC_ADDR_LEN-1:0] acc_addr;
    input wire [5:0] channel;

    output reg packet_detected;
    output reg [PACKET_LEN_MAX-PREAMBLE_LEN-1:0] packet_out;
    output reg [8:0] packet_len; // 9 bits can cover up to 512 bits

    // Internal signals
    reg [PACKET_LEN_MAX-PREAMBLE_LEN-1:0] rx_buffer;
    reg state, nextState;
    reg [8:0] bit_counter;
    reg packet_finished;
    wire acc_addr_matched;
    wire dewhitened;
    wire crc_pass;
    reg symbol_delayed;
    

    // Save RX buffer
    always @(posedge symbol_clk or negedge rst) begin
        if (!rst) begin
            rx_buffer <= 0;
        end
        else begin
            rx_buffer <= {rx_buffer[PACKET_LEN_MAX-PREAMBLE_LEN-2:0], (state ? dewhitened : symbol_in)};
        end
    end

    // Save Packet Output
    always @(posedge packet_detected or negedge rst) begin
        if (!rst) begin
            packet_out <= 0;
            packet_len <= 0;
        end 
        else begin
            packet_out <= rx_buffer;
            packet_len <= bit_counter + PREAMBLE_LEN + ACC_ADDR_LEN;
        end
    end

    // State Machine
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= 0;
        end 
        else if (en && symbol_clk) begin
            state <= nextState;
        end
    end

    always @(*) begin
        packet_detected = crc_pass && (bit_counter[2:0] == 3'b000);
        if (bit_counter == PACKET_LEN_MAX - PREAMBLE_LEN - ACC_ADDR_LEN)
            packet_finished = 1'b1;
        else
            packet_finished = 1'b0;

        case (state)
            1'b0: nextState = acc_addr_matched && en;
            1'b1: nextState = ~(packet_detected || packet_finished) && en;
            default: nextState = 1'b0;
        endcase
    end

    // Bit Counter
    always @(posedge symbol_clk or negedge rst) begin
        if (!rst)
            bit_counter <= 0;
        else if (en) begin
            if (state)
                bit_counter <= bit_counter + 1;
            else
                bit_counter <= 0;
        end
    end

    assign acc_addr_matched = (rx_buffer[ACC_ADDR_LEN-1:0] == acc_addr);

    // Instantiate Dewhiten
    dewhiten dw (
        .symbol_clk(symbol_clk),
        .en(state),
        .symbol_in(symbol_in),
        .dewhiten_init(channel),
        .symbol_out(dewhitened)
    );

    // Instantiate CRC
    crc #(
        .CRC_LEN(24)
    ) chk (
        .symbol_clk(symbol_clk),
        .en(state),
        .dewhitened(dewhitened),
        .crc_pass(crc_pass),
        .crc_init(CRC_INIT),
        .crc_poly(CRC_POLY)
    );

endmodule

module dewhiten (
    symbol_clk, en, symbol_in,
    dewhiten_init, symbol_out
);
    input wire symbol_clk, en, symbol_in;
    input wire [5:0] dewhiten_init;     // BLE channel (6 bits)
    output reg symbol_out;
    reg [6:0] lfsr;  // Whitening LFSR (7 bits)
    reg [6:0] next_lfsr;
    reg feedback;

    always @(posedge symbol_clk or negedge en) begin
        if (!en) begin
            lfsr = {1'b1, dewhiten_init};
            symbol_out = symbol_in ^ lfsr[0];
        end 
        else begin
            symbol_out = symbol_in ^ lfsr[0];
            feedback = lfsr[0];
            next_lfsr = {feedback, lfsr[6:1]};
            next_lfsr[2] = next_lfsr[2] ^ feedback; // feedback into bit 4
            lfsr = next_lfsr;
        end
    end
endmodule

module crc #(
    parameter CRC_LEN = 24
)(
    symbol_clk, en,
    dewhitened, crc_pass,
    crc_init, crc_poly
);
    input wire symbol_clk, en;
    input wire dewhitened;
    output reg crc_pass;
    input wire [CRC_LEN-1:0] crc_init;
    input wire [CRC_LEN-1:0] crc_poly;

    reg [CRC_LEN-1:0] crc_lfsr;
    reg msb, feedback;

    always @(posedge symbol_clk or negedge en) begin
        if (!en) begin
            crc_lfsr <= crc_init;
        end
        else if (en) begin
            msb = crc_lfsr[CRC_LEN-1];
            feedback = msb ^ dewhitened;
    
            crc_lfsr <= {crc_lfsr[CRC_LEN-2:0], 1'b0};
            if (feedback) begin
                crc_lfsr <= ({crc_lfsr[CRC_LEN-2:0], 1'b0}) ^ crc_poly;
            end
        end
    end
    always @(*) begin
        crc_pass = (crc_lfsr == 0);
    end
    
endmodule
