`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Jacob Louie
// 
// Create Date: 07/22/2024 03:25:25 PM
// Module Name: TOP
// Description: Top module
//////////////////////////////////////////////////////////////////////////////////

module TOP(
    input clk,                      // 16MHz SCuM ADC clock
    input [1:0] select,             // FPGA Switches
    input rst,                      // FPGA SW[15]
    input [3:0] I_BPF,              // I_BPF SCuM
    input [3:0] Q_BPF,              // I_BPF SCuM
    output [2:0] LED,               // FPGA switch LEDs (debug)
    output update,                  // clock for value/data
    output value,                   // binary decoded data
    output clk_Debug,
    output [3:0] I_Debug,
    output [3:0] Q_Debug,
    output packet_detectedLED          // led[2]
    );
    assign LED[1:0] = select;
    assign LED[2] = rst;    //Switch[15] = LED #15
    assign clk_Debug = clk;
    assign I_Debug = I_BPF;
    assign Q_Debug = Q_BPF;
    
    
    parameter TARGET = 25_000_000;
    reg [24:0]timer;
    reg timeOn; 
    
    assign packet_detectedLED = timeOn;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            timer <= 0;
            timeOn <= 0;
        end
        else if (packet_detected | timeOn) begin
            if (timer == TARGET - 1) begin
                timer <= 0;
                timeOn <= 0;
            end
            else begin
                timer <= timer + 1;
                timeOn <= 1;
            end
        end
        else begin
            timer <= 0;
            timeOn <= 0;
        end
    end

    Matched_Filter filter(
        .clk(clk),
        .select(select),
        .rst(rst),
        .update(update),
        .I_BPF(I_BPF),
        .Q_BPF(Q_BPF),
        //.MF_Output(TB_MF_Output),
        .data(value)
    );  
    
     Timing_Recovery_BLE Synch(
        .clk(clk),
        .select(select),			   
	    .rst(rst), 
	    .I_in(I_BPF), 
	    .Q_in(Q_BPF), // Set Low if no Input
        .update_data(update),	
	    .sample_point(3'd1),       // 1
	    .e_k_shift(4'd2),          // 2
        .tau_shift(5'd11)          // 11
    );
    
    parameter PACKET_LEN_MAX = 376;
    parameter PREAMBLE_LEN = 8;
    parameter ACC_ADDR_LEN = 32;
    parameter CRC_POLY = 24'h00065B;
    parameter CRC_INIT = 24'h555555;
    
    // dummy output wires
    wire [PACKET_LEN_MAX-PREAMBLE_LEN-1:0] packet_out;
    wire [8:0] packet_len;
   
    Packet_Sniffer #(
        .PACKET_LEN_MAX(PACKET_LEN_MAX),
        .PREAMBLE_LEN(PREAMBLE_LEN),
        .ACC_ADDR_LEN(ACC_ADDR_LEN),
        .CRC_POLY(CRC_POLY),
        .CRC_INIT(CRC_INIT)
    ) Detect(
        .symbol_clk(update),
        .rst(rst),
        .en(1'b1), 
        .symbol_in(value),
        .acc_addr(32'h6b7d9171),
        .channel(6'd37), 
        .packet_detected(packet_detected),
        .packet_out(packet_out),
        .packet_len(packet_len)
    );
endmodule
