
module da_wave_send(
    input                 clk         ,  //时钟
    input                 rst_n       ,  //复位信号，低电平有效
	 input         [1:0]        wave_flag   ,
    
    input        [7:0]    rd_data     ,  //ROM读出的数据
    output  reg  [9:0]    rd_addr     ,  //读ROM地址
    //DA芯片接口
    output                da_clk      ,  //DA(AD9708)驱动时钟,最大支持125Mhz时钟
    output       [7:0]    da_data        //输出给DA的数据  
    );

//parameter
//频率调节控制
parameter  FREQ_ADJ = 8'd0;  //频率调节,FREQ_ADJ的越大,最终输出的频率越低,范围0~255

//reg define
reg    [7:0]    freq_cnt  ;  //频率调节计数器

//*****************************************************
//**                    main code
//*****************************************************

//数据rd_data是在clk的上升沿更新的，所以DA芯片在clk的下降沿锁存数据是稳定的时刻
//而DA实际上在da_clk的上升沿锁存数据,所以时钟取反,这样clk的下降沿相当于da_clk的上升沿
assign  da_clk = ~clk;       
assign  da_data = rd_data;   //将读到的ROM数据赋值给DA数据端口

//频率调节计数器
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)
        freq_cnt <= 8'd0;
    else if(freq_cnt == FREQ_ADJ)    
        freq_cnt <= 8'd0;
    else         
        freq_cnt <= freq_cnt + 8'd1;
end

//读ROM地址


//波形变换
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)
        rd_addr <= 10'd0;
    else if(wave_flag == 0)begin
        if(freq_cnt == FREQ_ADJ) begin
          if(rd_addr >= 10'd0 && rd_addr < 10'd255)
				rd_addr <= rd_addr + 10'd1;
			 else begin
			   rd_addr <= 10'd0;
			 end	
        end    
    end
	 else if(wave_flag == 1)begin
        if(freq_cnt == FREQ_ADJ) begin
          if(rd_addr >= 10'd256 && rd_addr < 10'd511)
				rd_addr <= rd_addr + 10'd1;
			 else begin
			   rd_addr <= 10'd256;
			 end	
        end    
    end
	 else if(wave_flag == 2)begin
        if(freq_cnt == FREQ_ADJ) begin
          if(rd_addr >= 10'd512 && rd_addr < 10'd767)
				rd_addr <= rd_addr + 10'd1;
			 else begin
			   rd_addr <= 10'd512;
			 end	
        end    
    end
	 else begin
	   rd_addr <= rd_addr + 10'd1;
	 end
end
 


endmodule