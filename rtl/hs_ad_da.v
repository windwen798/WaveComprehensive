

module hs_ad_da(
    input                 sys_clk     ,  //系统时钟
    input                 sys_rst_n   ,  //系统复位，低电平有效
    input                 key         ,  //波形选择按钮
	 //DA芯片接口
    output                da_clk      ,  //DA(AD9708)驱动时钟,最大支持125Mhz时钟
    output    [7:0]       da_data     ,  //输出给DA的数据
    //AD芯片接口
    input     [7:0]       ad_data     ,  //AD输入数据
    //模拟输入电压超出量程标志(本次试验未用到)
    input                 ad_otr      ,  //0:在量程范围 1:超出量程
    output                ad_clk      ,   //AD(AD9280)驱动时钟,最大支持32Mhz时钟
	 output       tmds_clk_p,             // TMDS 时钟通道
    output       tmds_clk_n,
    output [2:0] tmds_data_p,            // TMDS 数据通道
    output [2:0] tmds_data_n 
);

//wire define 
wire      [9:0]    rd_addr;              //ROM读地址
wire      [7:0]    rd_data;              //ROM读出的数据

wire          pixel_clk;
wire          pixel_clk_5x;
wire          clk_locked;


wire  [11:0]  pixel_xpos_w;
wire  [11:0]  pixel_ypos_w;
wire  [23:0]  pixel_data_w;

wire          video_hs;
wire          video_vs;
wire          video_de;
wire  [23:0]  video_rgb;
wire   [7:0]   ram_out;
wire   [1:0]      flag;
wire				ad_buf_wren;
//reg define
reg      [1:0]       wave_flag;            //波形标志位
reg     [10:0]  sample_cnt = 0;
reg      [9:0]   rdaddress = 0;
reg      [2:0]   state;
reg     [31:0]  wait_cnt;

localparam       S_IDLE    = 0;
localparam       S_SAMPLE  = 1;
localparam       S_WAIT    = 2;

//*****************************************************
//**                    main code
//*****************************************************

//DA数据发送
da_wave_send u_da_wave_send(
    .clk         (sys_clk), 
    .rst_n       (sys_rst_n),
    .rd_data     (rd_data),
    .rd_addr     (rd_addr),
    .da_clk      (da_clk),
    .wave_flag   (flag),	 
    .da_data     (da_data)
    );

//ROM存储波形
rom_256x8b  u_rom_256x8b(
    .address    (rd_addr),
    .clock      (sys_clk),
    .q          (rd_data)
    );

//AD数据接收
ad_wave_rec u_ad_wave_rec(
    .clk         (sys_clk),
    .rst_n       (sys_rst_n),
    .ad_data     (ad_data),
    .ad_otr      (ad_otr),
    .ad_clk      (ad_clk)
    );
	 
	 //例化PLL IP核
pll_clk  u_pll_clk(
	.areset    (~sys_rst_n),
	.inclk0    (sys_clk),
	.c0        (pixel_clk),      //像素时钟
	.c1        (pixel_clk_5x),   //5倍像素时钟
	.locked    (clk_locked)
);

	 //例化视频显示驱动模块
video_driver u_video_driver(
    .pixel_clk      (pixel_clk),
    .sys_rst_n      (sys_rst_n),

    .video_hs       (video_hs),
    .video_vs       (video_vs),
    .video_de       (video_de),
    .video_rgb      (video_rgb),

    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .pixel_data     (pixel_data_w)
    );
	 

	 
	 //例化HDMI驱动模块
dvi_transmitter_top u_rgb2dvi_0(
    .pclk           (pixel_clk),
    .pclk_x5        (pixel_clk_5x),
    .reset_n        (sys_rst_n & clk_locked),
                
    .video_din      (video_rgb),
    .video_hsync    (video_hs), 
    .video_vsync    (video_vs),
    .video_de       (video_de),
                
    .tmds_clk_p     (tmds_clk_p),
    .tmds_clk_n     (tmds_clk_n),
    .tmds_data_p    (tmds_data_p),
    .tmds_data_n    (tmds_data_n)
    );
	 
	 ram1024_8 my_ram(
	.data			(ad_data),
	.wraddress	(sample_cnt),
	.wren			(ad_buf_wren),
	.wrclock		(ad_clk),
	
	.rdclock		(pixel_clk),
	.rdaddress	(rdaddress),
	
	.q				(ram_out)
);

video_display  my_video_display(	//例化视频显示模块；
    .pixel_clk      (pixel_clk),
    .sys_rst_n      (sys_rst_n),
	 .datain			  (ram_out),

    .pixel_xpos     (pixel_xpos_w),
    .pixel_ypos     (pixel_ypos_w),
    .pixel_data     (pixel_data_w)
    );

 always @(posedge key or negedge sys_rst_n) begin
    if(sys_rst_n == 1'b0)
      wave_flag <= 0;
	 else if(wave_flag < 2)begin
	 wave_flag <= (wave_flag+1'b1); 
	 end
	      else begin
			wave_flag <= 0;
			end

end

always@(posedge ad_clk or negedge sys_rst_n)
begin
	if(!sys_rst_n)
	begin
		state <= S_IDLE;
		wait_cnt <= 32'd0;
		sample_cnt <= 11'd0;
	end
	else
		case(state)
			S_IDLE:
			begin
				state <= S_SAMPLE;
			end
			S_SAMPLE:
			begin
					if(sample_cnt == 11'd1023)
					begin
						sample_cnt <= 11'd0;
						state <= S_WAIT;
					end
					else
					begin
						sample_cnt <= sample_cnt + 11'd1;
					end
			end		
			S_WAIT:
			begin
//`ifdef  TRIGGER				
//				if(adc_data_valid == 1'b1 && adc_data_d1 < 8'd127 && adc_data_d0 >= 8'd127)
//					state <= S_SAMPLE;
//`else
				if(wait_cnt == 32'd6_000_000)
				begin
					state <= S_SAMPLE;
					wait_cnt <= 32'd0;
				end
				else
				begin
					wait_cnt <= wait_cnt + 32'd1;
				end
//`endif					
			end	
			default:
				state <= S_IDLE;
		endcase
end 

always@(posedge pixel_clk)
begin
	if(pixel_ypos_w >= 12'd200 && pixel_ypos_w <= 12'd510 && pixel_xpos_w >= 12'd9 && pixel_xpos_w  <= 12'd1911)
		rdaddress <= rdaddress + 10'd1;
	else
		rdaddress <= 10'd0;
end

assign ad_buf_wren = (state == S_SAMPLE) ? 1'b1 : 1'b0;


assign flag = wave_flag;  

endmodule