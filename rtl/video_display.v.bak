module  video_display(
    input             pixel_clk,                //驱动时钟
    input             sys_rst_n,                //复位信号
	 input      [7:0]  datain,
    
    input      [11:0] pixel_xpos,               //像素点横坐标
    input      [11:0] pixel_ypos,               //像素点纵坐标    
    output reg [23:0] pixel_data                //像素点数据
    );    

//parameter define    
parameter  H_DISP  = 12'd1920;                  //分辨率--行
parameter  V_DISP  = 12'd1080;                   //分辨率--列

localparam SIDE_W  = 12'd40;                    //屏幕边框宽度
localparam BLOCK_W = 12'd40;                    //方块宽度
localparam BLUE    = 24'b00000000_00000000_11111111;    //屏幕边框颜色 蓝色
localparam WHITE   = 24'b11111111_11111111_11111111;    //背景颜色 白色
localparam BLACK   = 24'b00000000_00000000_00000000;    //方块颜色 黑色
localparam RED     = 24'b11111111_00000000_00000000;

//reg define
//reg [11:0] block_x = SIDE_W ;                             //方块左上角横坐标
//reg [11:0] block_y = SIDE_W ;                             //方块左上角纵坐标
//reg [21:0] div_cnt;                             //时钟分频计数器
//reg        h_direct;                            //方块水平移动方向，1：右移，0：左移
//reg        v_direct;                            //方块竖直移动方向，1：向下，0：向上
reg		  region_active;
reg [8:0]		  grid_x = 0;
reg [23:0]  pos_data;

//wire define   
wire move_en;                                   //方块移动使能信号，频率为100hz

//*****************************************************
//**                    main code
//*****************************************************
//assign move_en = (div_cnt == 22'd742500) ? 1'b1 : 1'b0;

//通过对vga驱动时钟计数，实现时钟分频
//always @(posedge pixel_clk ) begin         
//    if (!sys_rst_n)
//        div_cnt <= 22'd0;
//    else begin
//        if(div_cnt < 22'd742500) 
//            div_cnt <= div_cnt + 1'b1;
//        else
//            div_cnt <= 22'd0;                   //计数达10ms后清零
//    end
//end
	
always@(posedge pixel_clk)
begin
	if(pixel_ypos >= 12'd200 && pixel_ypos <= 12'd510 && pixel_xpos >= 12'd9 && pixel_xpos  <= 12'd1911)
		region_active <= 1'b1;
	else
		region_active <= 1'b0;
end

always@(posedge pixel_clk)
begin
	if(region_active == 1'b1)
		grid_x <= (grid_x == 9'd9) ? 9'd0 : grid_x + 9'd1;
	else
		grid_x <= 9'd0;
end

always@(posedge pixel_clk)
begin
	if(region_active == 1'b1)
		if(12'd484 - pixel_ypos == {4'd0,datain} || 12'd485 - pixel_ypos == {4'd0,datain} || 12'd483 - pixel_ypos == {4'd0,datain})
			pixel_data <= 24'h000000;
		else
			pixel_data <= pos_data;
	else
		pixel_data <= pos_data;
end

always@(posedge pixel_clk)
begin
	if(region_active == 1'b1)
		if(pixel_ypos == 12'd484 || pixel_ypos == 12'd232 || pixel_ypos == 12'd358 || 
		  (pixel_ypos < 12'd484 && pixel_ypos > 12'd232 &&grid_x == 9'd9 && pixel_ypos[0] == 1'b0))
			pos_data <= {8'd139,8'd129,8'd29};
		else
//		pos_data <= 24'h000000;
		pos_data <= WHITE;
	else
		pos_data <= WHITE;
end
endmodule 