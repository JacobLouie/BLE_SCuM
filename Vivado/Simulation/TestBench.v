`timescale 1ps / 1fs

module TestBench();
    reg clk;
    reg [1:0] select;
    reg rst;
    reg [31:0] sampleCount;
    wire Test_Switch;
    wire update_data;
    wire new_data;
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
        // BLE mode = 2 (1.5MHz-2MHz)
        // BLE mode = 3 (1MHz-1.5MHz)
        select = 1; 
        rst = 0;
        sampleCount = 0;
        #100
        //#162.5
        rst = 1;
        clk = 1;
        
           
        fd = $fopen("../../../../VerilogMFOut.txt", "w");
        #1248000    // 802.15.4
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
    assign new_data = update_data;
    
    Matched_Filter filter(
        .clk(clk),
        .select(select),
        .rst(rst),
        .update(new_data),
        .I_BPF(I_data),
        .Q_BPF(Q_data),
        //.MF_Output(TB_MF_Output),
        .data(TB_Output_data)
    );    
   
    Timing_Recovery_BLE Synch(
        .clk(clk),			   
	    .rst(rst), 
	    .I_in(I_data), 
	    .Q_in(Q_data), // Set Low if no Input
        .update_data(update_data),	
	    .sample_point(1),       // 1
	    .e_k_shift(2),          // 2
        .tau_shift(11)          // 11
    );

    always @(posedge new_data)begin
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
