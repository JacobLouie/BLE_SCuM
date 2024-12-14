`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Jacob Louie
// 
// Create Date: 12/09/2023 01:52:37 PM
// Module Name: Matched_Filter
// Description: Matched Filter for Bluetooth_LE and 802.15.4
//////////////////////////////////////////////////////////////////////////////////

module Matched_Filter(
    input wire clk,                                 // 16MHz clock
    input wire [1:0] select,                        // Select between BLE template and 802.15.4 template (0 = BLE, 1 = 802.15.4)
                                                    // Changes the BLE templates (2 = BLE mode with 1.5MHz and 2 MHz template)
                                                    // Changes the BLE templates (3 = BLE mode with 1MHz and 1.5MHz template)
    input wire rst,                                 // Reset for buffer
    input wire update,                              // get new data value                               
    input wire [3:0] I_BPF,                         // Band Pass Fillter 4 bit ADC as input
    input wire [3:0] Q_BPF,                         // Band Pass Fillter 4 bit ADC as input
    //output wire [7:0] MF_Output,                    // debug sudo score value [7:4] = High MHz score, [3:0] = Low MHz score
    output wire data                                // 1/0 output
    );
    localparam BUFFER_SIZE = 16;                     // 1 periods for BLE (8 = 1 period for 802.15.4)
    integer i;                                      // counter for loop
    reg signed [3:0] I_Buffer [0:BUFFER_SIZE - 1];  // Array size 8 of 4 bit values (I_BPF)
    reg signed [3:0] Q_Buffer [0:BUFFER_SIZE - 1];  // Array size 8 of 4 bit values (Q_BPF)
    
    // Initialize Templates for Bluetooth LE
    // BLE needs 1MHz/1.5MHz and 2MHz
    // Array size 8 of 5 bit values (ADC + Sign)
    wire signed [4:0] Template_Cos1MHz [0:15];              // Cosine   1 MHz
    wire signed [4:0] Template_Sin1MHz [0:15];              // Sine     1 MHz
    wire signed [4:0] Template_Cos15MHz [0:15];             // Cosine   1.5 MHz
    wire signed [4:0] Template_Sin15MHz [0:15];             // Sine     1.5 MHz
    wire signed [4:0] Template_Cos25MHz [0:15];             // Cosine   2.5 MHz
    wire signed [4:0] Template_Sin25MHz [0:15];             // Sine     2.5 MHz
    
    // Cosine 1MHz
    assign Template_Cos1MHz[0] = 5'd15;
    assign Template_Cos1MHz[1] = 5'd14;
    assign Template_Cos1MHz[2] = 5'd11;
    assign Template_Cos1MHz[3] = 5'd6;
    assign Template_Cos1MHz[4] = 5'd0;
    assign Template_Cos1MHz[5] = -5'd6;
    assign Template_Cos1MHz[6] = -5'd11;
    assign Template_Cos1MHz[7] = -5'd14;
    assign Template_Cos1MHz[8] = -5'd15;
    assign Template_Cos1MHz[9] = -5'd14;
    assign Template_Cos1MHz[10] = -5'd11;
    assign Template_Cos1MHz[11] = -5'd6;
    assign Template_Cos1MHz[12] = 5'd0;
    assign Template_Cos1MHz[13] = 5'd6;
    assign Template_Cos1MHz[14] = 5'd11;
    assign Template_Cos1MHz[15] = 5'd14;
    
    // Sine 1MHz
    assign Template_Sin1MHz[0] = 5'd0;
    assign Template_Sin1MHz[1] = 5'd6;
    assign Template_Sin1MHz[2] = 5'd11;
    assign Template_Sin1MHz[3] = 5'd14;
    assign Template_Sin1MHz[4] = 5'd15;
    assign Template_Sin1MHz[5] = 5'd14;
    assign Template_Sin1MHz[6] = 5'd11;
    assign Template_Sin1MHz[7] = 5'd6;
    assign Template_Sin1MHz[8] = 5'd0;
    assign Template_Sin1MHz[9] = -5'd6;
    assign Template_Sin1MHz[10] = -5'd11;
    assign Template_Sin1MHz[11] = -5'd14;
    assign Template_Sin1MHz[12] = -5'd15;
    assign Template_Sin1MHz[13] = -5'd14;
    assign Template_Sin1MHz[14] = -5'd11;
    assign Template_Sin1MHz[15] = -5'd6;
    
    // Cosine 1.5MHz
    assign Template_Cos15MHz[0] = 5'd15;
    assign Template_Cos15MHz[1] = 5'd12;
    assign Template_Cos15MHz[2] = 5'd6;
    assign Template_Cos15MHz[3] = -5'd3;
    assign Template_Cos15MHz[4] = -5'd11;
    assign Template_Cos15MHz[5] = -5'd15;
    assign Template_Cos15MHz[6] = -5'd14;
    assign Template_Cos15MHz[7] = -5'd8;
    assign Template_Cos15MHz[8] = 5'd0;
    assign Template_Cos15MHz[9] = 5'd8;
    assign Template_Cos15MHz[10] = 5'd14;
    assign Template_Cos15MHz[11] = 5'd15;
    assign Template_Cos15MHz[12] = 5'd11;
    assign Template_Cos15MHz[13] = 5'd3;
    assign Template_Cos15MHz[14] = -5'd6;
    assign Template_Cos15MHz[15] = -5'd12;

    // Sine 1.5MHz
    assign Template_Sin15MHz[0] = 5'd0;
    assign Template_Sin15MHz[1] = 5'd8;
    assign Template_Sin15MHz[2] = 5'd14;
    assign Template_Sin15MHz[3] = 5'd15;
    assign Template_Sin15MHz[4] = 5'd11;
    assign Template_Sin15MHz[5] = 5'd3;
    assign Template_Sin15MHz[6] = -5'd6;
    assign Template_Sin15MHz[7] = -5'd12;
    assign Template_Sin15MHz[8] = -5'd15;
    assign Template_Sin15MHz[9] = -5'd12;
    assign Template_Sin15MHz[10] = -5'd6;
    assign Template_Sin15MHz[11] = 5'd3;
    assign Template_Sin15MHz[12] = 5'd11;
    assign Template_Sin15MHz[13] = 5'd15;
    assign Template_Sin15MHz[14] = 5'd14;
    assign Template_Sin15MHz[15] = 5'd8;
    
    // Cosine 2.5MHz
    assign Template_Cos25MHz[0] = 5'd15;
    assign Template_Cos25MHz[1] = 5'd8;
    assign Template_Cos25MHz[2] = -5'd6;
    assign Template_Cos25MHz[3] = -5'd15;
    assign Template_Cos25MHz[4] = -5'd11;
    assign Template_Cos25MHz[5] = 5'd3;
    assign Template_Cos25MHz[6] = 5'd14;
    assign Template_Cos25MHz[7] = 5'd12;
    assign Template_Cos25MHz[8] = 5'd0;
    assign Template_Cos25MHz[9] = -5'd12;
    assign Template_Cos25MHz[10] = -5'd14;
    assign Template_Cos25MHz[11] = -5'd3;
    assign Template_Cos25MHz[12] = 5'd11;
    assign Template_Cos25MHz[13] = 5'd15;
    assign Template_Cos25MHz[14] = 5'd6;
    assign Template_Cos25MHz[15] = -5'd8;

    // Sine 2.5MHz
    assign Template_Sin25MHz[0] = 5'd0;
    assign Template_Sin25MHz[1] = 5'd12;
    assign Template_Sin25MHz[2] = 5'd14;
    assign Template_Sin25MHz[3] = 5'd3;
    assign Template_Sin25MHz[4] = -5'd11;
    assign Template_Sin25MHz[5] = -5'd15;
    assign Template_Sin25MHz[6] = -5'd6;
    assign Template_Sin25MHz[7] = 5'd8;
    assign Template_Sin25MHz[8] = 5'd15;
    assign Template_Sin25MHz[9] = 5'd8;
    assign Template_Sin25MHz[10] = -5'd6;
    assign Template_Sin25MHz[11] = -5'd15;
    assign Template_Sin25MHz[12] = -5'd11;
    assign Template_Sin25MHz[13] = 5'd3;
    assign Template_Sin25MHz[14] = 5'd14;
    assign Template_Sin25MHz[15] = 5'd12;
     
    // Initialize Templates for 802.15.4
    // Array size 8 of 5 bit values (ADC + Sign)
    wire signed [4:0] Template_Cos2MHz [0:15];              // Cosine   2MHz
    wire signed [4:0] Template_Sin2MHz [0:15];              // Sine     2MHz
    wire signed [4:0] Template_Cos3MHz [0:15];              // Cosine   3MHz
    wire signed [4:0] Template_Sin3MHz [0:15];              // Sine     3MHz
    
    // Cosine 2MHz
    assign Template_Cos2MHz[0] = 5'd15;
    assign Template_Cos2MHz[1] = 5'd11;
    assign Template_Cos2MHz[2] = 5'd0;
    assign Template_Cos2MHz[3] = -5'd11;
    assign Template_Cos2MHz[4] = -5'd15;
    assign Template_Cos2MHz[5] = -5'd11;
    assign Template_Cos2MHz[6] = 5'd0;
    assign Template_Cos2MHz[7] = 5'd11;
    assign Template_Cos2MHz[8] = 5'd15;
    assign Template_Cos2MHz[9] = 5'd11;
    assign Template_Cos2MHz[10] = 5'd0;
    assign Template_Cos2MHz[11] = -5'd11;
    assign Template_Cos2MHz[12] = -5'd15;
    assign Template_Cos2MHz[13] = -5'd11;
    assign Template_Cos2MHz[14] = 5'd0;
    assign Template_Cos2MHz[15] = 5'd11;
        
    // Sine 2MHz
    assign Template_Sin2MHz[0] = 5'd0;
    assign Template_Sin2MHz[1] = 5'd11;
    assign Template_Sin2MHz[2] = 5'd15;
    assign Template_Sin2MHz[3] = 5'd11;
    assign Template_Sin2MHz[4] = 5'd0;
    assign Template_Sin2MHz[5] = -5'd11;
    assign Template_Sin2MHz[6] = -5'd15;
    assign Template_Sin2MHz[7] = -5'd11;
    assign Template_Sin2MHz[8] = 5'd0;
    assign Template_Sin2MHz[9] = 5'd11;
    assign Template_Sin2MHz[10] = 5'd15;
    assign Template_Sin2MHz[11] = 5'd11;
    assign Template_Sin2MHz[12] = 5'd0;
    assign Template_Sin2MHz[13] = -5'd11;
    assign Template_Sin2MHz[14] = -5'd15;
    assign Template_Sin2MHz[15] = -5'd11;
    
    // Cosine 3MHz
    assign Template_Cos3MHz[0] = 5'd15;
    assign Template_Cos3MHz[1] = 5'd6;
    assign Template_Cos3MHz[2] = -5'd11;
    assign Template_Cos3MHz[3] = -5'd14;
    assign Template_Cos3MHz[4] = 5'd0;
    assign Template_Cos3MHz[5] = 5'd14;
    assign Template_Cos3MHz[6] = 5'd11;
    assign Template_Cos3MHz[7] = -5'd6;
    assign Template_Cos3MHz[8] = -5'd15;
    assign Template_Cos3MHz[9] = -5'd6;
    assign Template_Cos3MHz[10] = 5'd11;
    assign Template_Cos3MHz[11] = 5'd14;
    assign Template_Cos3MHz[12] = 5'd0;
    assign Template_Cos3MHz[13] = -5'd14;
    assign Template_Cos3MHz[14] = -5'd11;
    assign Template_Cos3MHz[15] = 5'd6;
  
    // Sine 3MHz
    assign Template_Sin3MHz[0] = 5'd0;
    assign Template_Sin3MHz[1] = 5'd14;
    assign Template_Sin3MHz[2] = 5'd11;
    assign Template_Sin3MHz[3] = -5'd6;
    assign Template_Sin3MHz[4] = -5'd15;
    assign Template_Sin3MHz[5] = -5'd6;
    assign Template_Sin3MHz[6] = 5'd11;
    assign Template_Sin3MHz[7] = 5'd14;
    assign Template_Sin3MHz[8] = 5'd0;
    assign Template_Sin3MHz[9] = -5'd14;
    assign Template_Sin3MHz[10] = -5'd11;
    assign Template_Sin3MHz[11] = 5'd6;
    assign Template_Sin3MHz[12] = 5'd15;
    assign Template_Sin3MHz[13] = 5'd6;
    assign Template_Sin3MHz[14] = -5'd11;
    assign Template_Sin3MHz[15] = -5'd14;

    always@(posedge clk or negedge rst)begin
        // Clear the buffer 
        if(!rst) begin
            for(i = 0; i < BUFFER_SIZE; i = i + 1)begin 
                I_Buffer[i] <= 0;
                Q_Buffer[i] <= 0;
            end
        end
        // Shift in new I_BPF value
        else begin
            for (i = 0; i < BUFFER_SIZE-1; i = i + 1) begin 
                I_Buffer[i] <= I_Buffer[i + 1];
                Q_Buffer[i] <= Q_Buffer[i + 1];
            end
            I_Buffer[BUFFER_SIZE - 1] <= I_BPF;
            Q_Buffer[BUFFER_SIZE - 1] <= Q_BPF;
        end
    end
    
    // Template Correlation
    // Correlation between template and I_BPF
    reg signed [7:0] temp_score1, temp_score2, temp_score3, temp_score4;
    reg signed [7:0] temp_score5, temp_score6, temp_score7, temp_score8;
    reg signed [11:0] sum1_cosine, sum2_sine, sum3_cosine, sum4_sine;
    reg signed [11:0] sum5_cosine, sum6_sine, sum7_cosine, sum8_sine;

    
    // Squared in order to make remove negative (Magnitude)
    reg signed [23:0] sum1_squared_cosine, sum2_squared_sine,       
                      sum3_squared_cosine, sum4_squared_sine;
    reg signed [23:0] sum5_squared_cosine, sum6_squared_sine,       
                      sum7_squared_cosine, sum8_squared_sine;
                      
    // Final score values
    wire signed [25:0]Low_MHz_Score, High_MHz_Score;
    
    //Counter for buffer array    
    integer j; 
    
    always @(* ) begin
        // initialize temp scores
        temp_score1 = 0;
        temp_score2 = 0;
        temp_score3 = 0;
        temp_score4 = 0;
        temp_score5 = 0;
        temp_score6 = 0;
        temp_score7 = 0;
        temp_score8 = 0;
        // initialize sums
        sum1_cosine = 0;
        sum2_sine = 0;
        sum3_cosine = 0;
        sum4_sine = 0;
        sum5_cosine = 0;
        sum6_sine = 0;
        sum7_cosine = 0;
        sum8_sine = 0;
        // initialize sums^2
        sum1_squared_cosine = 0;
        sum2_squared_sine = 0;
        sum3_squared_cosine = 0;
        sum4_squared_sine = 0;
        sum5_squared_cosine = 0;
        sum6_squared_sine = 0;
        sum7_squared_cosine = 0;
        sum8_squared_sine = 0;
        // Get score by mutiplying the I_BPF in the buffer by the templates
        // For 802.15.4
        if(select == 1) begin
            // Data length is 8 bits long for 802.15.4
            for (j = 0; j < 8; j = j + 1) begin
                // Low MHz
                temp_score1 = Template_Cos2MHz[j] * I_Buffer[j+8];
                temp_score2 = Template_Sin2MHz[j] * I_Buffer[j+8];
                temp_score5 = Template_Cos2MHz[j] * Q_Buffer[j+8];
                temp_score6 = Template_Sin2MHz[j] * Q_Buffer[j+8];
                // High MHz
                temp_score3 = Template_Cos3MHz[j] * I_Buffer[j+8];
                temp_score4 = Template_Sin3MHz[j] * I_Buffer[j+8];
                temp_score7 = Template_Cos3MHz[j] * Q_Buffer[j+8];
                temp_score8 = Template_Sin3MHz[j] * Q_Buffer[j+8];
        
                // Low MHz
                sum1_cosine = sum1_cosine + temp_score1;
                sum2_sine = sum2_sine + temp_score2; 
                sum5_cosine = sum5_cosine + temp_score5;
                sum6_sine = sum6_sine + temp_score6;
                // High MHz
                sum3_cosine = sum3_cosine + temp_score3; 
                sum4_sine = sum4_sine + temp_score4;
                sum7_cosine = sum7_cosine + temp_score7; 
                sum8_sine = sum8_sine + temp_score8;
            end
        end
        // For Bluetooth LE (1.5MHz - 2MHz template)
        else if(select == 2) begin
            // Data length is 16 bits long for BLE
            for (j = 0; j < 16; j = j + 1) begin
                // Low MHz
                temp_score1 = Template_Cos15MHz[j] * I_Buffer[j];
                temp_score2 = Template_Sin15MHz[j] * I_Buffer[j];
                temp_score5 = Template_Cos15MHz[j] * Q_Buffer[j];
                temp_score6 = Template_Sin15MHz[j] * Q_Buffer[j];
                // High MHz
                temp_score3 = Template_Cos2MHz[j] * I_Buffer[j];
                temp_score4 = Template_Sin2MHz[j] * I_Buffer[j];
                temp_score7 = Template_Cos2MHz[j] * Q_Buffer[j];
                temp_score8 = Template_Sin2MHz[j] * Q_Buffer[j];
    
                // Low MHz
                sum1_cosine = sum1_cosine + temp_score1;
                sum2_sine = sum2_sine + temp_score2; 
                sum5_cosine = sum5_cosine + temp_score5;
                sum6_sine = sum6_sine + temp_score6;
                // High MHz
                sum3_cosine = sum3_cosine + temp_score3; 
                sum4_sine = sum4_sine + temp_score4;
                sum7_cosine = sum7_cosine + temp_score7; 
                sum8_sine = sum8_sine + temp_score8;
            end
        
        end
        // For Bluetooth LE (1MHz - 1.5MHz template)
        else if (select == 3) begin
            // Data length is 16 bits long for BLE
            for (j = 0; j < 16; j = j + 1) begin
                // Low MHz
                temp_score1 = Template_Cos1MHz[j] * I_Buffer[j];
                temp_score2 = Template_Sin1MHz[j] * I_Buffer[j];
                temp_score5 = Template_Cos1MHz[j] * Q_Buffer[j];
                temp_score6 = Template_Sin1MHz[j] * Q_Buffer[j];
                // High MHz
                temp_score3 = Template_Cos15MHz[j] * I_Buffer[j];
                temp_score4 = Template_Sin15MHz[j] * I_Buffer[j];
                temp_score7 = Template_Cos15MHz[j] * Q_Buffer[j];
                temp_score8 = Template_Sin15MHz[j] * Q_Buffer[j];
                
                // Low MHz
                sum1_cosine = sum1_cosine + temp_score1;
                sum2_sine = sum2_sine + temp_score2; 
                sum5_cosine = sum5_cosine + temp_score5;
                sum6_sine = sum6_sine + temp_score6;
                // High MHz
                sum3_cosine = sum3_cosine + temp_score3; 
                sum4_sine = sum4_sine + temp_score4;
                sum7_cosine = sum7_cosine + temp_score7; 
                sum8_sine = sum8_sine + temp_score8;
            end          
        end    
        // For Bluetooth LE (2MHz - 2.5MHz template)
        else begin
            // Data length is 16 bits long for BLE
            for (j = 0; j < 16; j = j + 1) begin
                // Low MHz
                temp_score1 = Template_Cos2MHz[j] * I_Buffer[j];
                temp_score2 = Template_Sin2MHz[j] * I_Buffer[j];
                temp_score5 = Template_Cos2MHz[j] * Q_Buffer[j];
                temp_score6 = Template_Sin2MHz[j] * Q_Buffer[j];
                // High MHz
                temp_score3 = Template_Cos3MHz[j] * I_Buffer[j];
                temp_score4 = Template_Sin3MHz[j] * I_Buffer[j];
                temp_score7 = Template_Cos3MHz[j] * Q_Buffer[j];
                temp_score8 = Template_Sin3MHz[j] * Q_Buffer[j];
                
                // Low MHz
                sum1_cosine = sum1_cosine + temp_score1;
                sum2_sine = sum2_sine + temp_score2; 
                sum5_cosine = sum5_cosine + temp_score5;
                sum6_sine = sum6_sine + temp_score6;
                // High MHz
                sum3_cosine = sum3_cosine + temp_score3; 
                sum4_sine = sum4_sine + temp_score4;
                sum7_cosine = sum7_cosine + temp_score7; 
                sum8_sine = sum8_sine + temp_score8;
            end
        end 
        // and square each sum
        // Low MHz
        sum1_squared_cosine = sum1_cosine * sum1_cosine;
        sum2_squared_sine = sum2_sine * sum2_sine;
        sum5_squared_cosine = sum5_cosine * sum5_cosine;
        sum6_squared_sine = sum6_sine * sum6_sine; 
        // High MHz
        sum3_squared_cosine = sum3_cosine * sum3_cosine; 
        sum4_squared_sine = sum4_sine * sum4_sine;  
        sum7_squared_cosine = sum7_cosine * sum7_cosine; 
        sum8_squared_sine = sum8_sine * sum8_sine;      
    end 
    // Add 1MHz(BLE)    /1.5MHz(BLE)    /2MHz(BLE)      /2MHz(802.15.4) score together
    assign Low_MHz_Score = sum1_squared_cosine + sum2_squared_sine + sum5_squared_cosine + sum6_squared_sine;
    // Add 1.5MHz(BLE)  /2MHz(BLE)      /2.5MHz(BLE)    /3MHz(802.15.4) score together
    assign High_MHz_Score = sum3_squared_cosine + sum4_squared_sine + sum7_squared_cosine + sum8_squared_sine;  
    // Use this to compare to SCUM value (debug info);
    //assign MF_Output = {High_MHz_Score[16:13],Low_MHz_Score[16:13]};
    
    // Assign the value of 1 and 0 to eather 1MHz or 2MHz for BLE (2MHZ or 3MHZ for 801.15.4)
    reg reg_value;
    wire value;
    // If Low_MHz_Score is greater than the data is 0
    assign value = Low_MHz_Score > High_MHz_Score ? 0:1;
    
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            reg_value <= 0;
        end
        else if(update) begin 
            reg_value <= value;
        end
    end
    assign data = reg_value;
    
endmodule