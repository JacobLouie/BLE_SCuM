`timescale 1ps / 1fs

module TestBench();
    parameter PACKET_LEN_MAX = 376;
    parameter PREAMBLE_LEN = 8;
    parameter ACC_ADDR_LEN = 32;
    parameter CRC_POLY = 24'h00065B;
    parameter CRC_INIT = 24'h555555;
    reg clk;
    reg [1:0] select;
    reg rst;
    reg [31:0] sampleCount;
    wire Test_Switch;
    wire update_data;
    wire [3:0] I_Test;
    wire [3:0] Q_Test;
    wire [3:0] I_data;
    wire [3:0] Q_data;
    wire [7:0] TB_MF_Output;
    wire TB_Output_data;
    integer fd; 
    initial begin
        clk = 0;
        // Mode select 
        // 802.15.4 mode = 1 (2MHz-3MHz)
        // BLE mode = 0 (2MHz-2.5MHz)
        // BLE mode = 2 (2MHz-3MHz)
        // BLE mode = 3 (2.25MHz-2.75MHz)
        select = 3; 
        rst = 0;
        sampleCount = 0;
        #100
        //#162.5
        rst = 1;
        clk = 1;
        
           
        fd = $fopen("../../../../VerilogMFOut.txt", "w");
        //#1248000    // 802.15.4
        #21250000    // 802.15.4
        
        //#800000   //BLE
        $fclose(fd);
   end
   always #31.25 clk = ~clk;    // 16 MHz
    I_Q_data BPF_TEST(
        .clk(clk),
        .switch(Test_Switch),
        .Test_DataI(I_Test),
        .Test_DataQ(Q_Test)
    );
    assign I_data = I_Test;
    assign Q_data = Q_Test;
    //assign new_data = Test_Switch;
    
    
    parameter TARGET = 13_000;
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
        .update(update_data),
        .I_BPF(I_data),
        .Q_BPF(Q_data),
        //.MF_Output(TB_MF_Output),
        .data(TB_Output_data)
    );    
   
    Timing_Recovery_BLE Synch(
        .clk(clk),	
        .select(select),		   
	    .rst(rst), 
	    .I_in(I_data), 
	    .Q_in(Q_data), // Set Low if no Input
        .update_data(update_data),	
	    .sample_point(3'd1),       // 1
	    .e_k_shift(4'd2),          // 2
        .tau_shift(5'd11)          // 11
    );

    wire packet_out, packet_len;
    wire packet_detected;   
    Packet_Sniffer #(
        .PACKET_LEN_MAX(PACKET_LEN_MAX),
        .PREAMBLE_LEN(PREAMBLE_LEN),
        .ACC_ADDR_LEN(ACC_ADDR_LEN),
        .CRC_POLY(CRC_POLY),
        .CRC_INIT(CRC_INIT)
    ) dut (
        //.clk(clk),
        .symbol_clk(update_data),
        .rst(rst),
        .en(1'b1),
        .symbol_in(TB_Output_data),
        .acc_addr(32'h6b7d9171),
        .channel(6'd37),
        .packet_detected(packet_detected),
        .packet_out(packet_out),
        .packet_len(packet_len)
    );

    always @(posedge update_data)begin
            //$display(TB_Output_data);
            $fdisplay(fd,TB_Output_data);  
    end  
    
    always @(posedge clk or negedge rst)begin
   
        if (!rst) begin
            sampleCount = 0;
		end
        else begin 
            sampleCount = sampleCount + 1;
        end
    end  

endmodule
