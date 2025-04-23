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
    output [3:0] Q_Debug
    );
    
    assign LED[1:0] = select;
    assign LED[2] = rst;    //Switch[15] = LED #15
    assign clk_Debug = clk;
    assign I_Debug = I_BPF;
    assign Q_Debug = Q_BPF;

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

endmodule
