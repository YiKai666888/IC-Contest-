`timescale 1ns / 1ps
module  CONV(clk, reset, busy, ready, iaddr, idata, cwr, caddr_wr, cdata_wr, crd, caddr_rd, cdata_rd, csel);
input		  clk;
input		  reset;
input         ready;
input  signed[19:0] cdata_rd;
input signed [19:0] idata;
output reg busy;
output reg cwr;
output reg crd;
output reg [11:0] iaddr;
output reg [11:0] caddr_wr;
output reg [19:0] cdata_wr;
output reg [11:0] caddr_rd;
output reg [2:0] csel;
wire[11:0] iaddr_add1,iaddr_add63,iaddr_sub63,iaddr_add64,iaddr_sub64,iaddr_sub127,caddr_wr_sub63;
wire signed[40:0] a0,a1,a2,a3,a4,a5,a6,a7,a8;
wire signed  [40:0] wire_42bits;
//reg signed [41:0]wire_42bits;
//wire [11:0] iaddr_add1,iaddr_add63,iaddr_sub63,iaddr_add64,iaddr_sub127,caddr_wr_sub63;
wire left,right,left_top,top,right_top,left_bottom,bottom,right_bottom,layer0_cal ;
reg [3:0] counter_4bits,counter_4bits_set;
reg[11:0] counter_0to4095;
reg signed [19:0] conv_reg0,conv_reg1,conv_reg2,conv_reg3,conv_reg4,conv_reg5,conv_reg6,conv_reg7,conv_reg8,k0,k1,k2,k3,k4,k5,k6,k7,k8;
reg signed [39:0] bias;
wire  [19:0] wire_20bits;
reg[4:0] cs,ns;
parameter  ker0_bias = 40'h0013100000, ker1_bias = 40'h0f72950000; //後面補四個零
parameter  ker00 = 20'h0a89e, ker01 = 20'h092d5, ker02 = 20'h06d43, ker03 = 20'h1004, ker04 = 20'hf8f71, ker05 = 20'hf6e54, ker06 = 20'hfa6d7, ker07 = 20'hfc834, ker08 = 20'hfac19;
parameter  ker10 = 20'hfdb55, ker11 = 20'h02992, ker12 = 20'hfc994, ker13 = 20'h050fd, ker14 = 20'h02f20, ker15 = 20'h0202d, ker16 = 20'h03bd7, ker17 = 20'hfd369, ker18 = 20'h05e68;
parameter  idle = 5'd0, busy_sig = 5'd1, layer0_read_data = 5'd2, layer0_calculate_k0 = 5'd3, layer0_calculate_k1 = 5'd4, layer0_caddr_wr = 5'd5, layer1_ker0_read = 5'd6,layer1_ker0_write = 5'd7,layer1_ker1_read = 5'd8,layer1_ker1_write = 5'd9,layer2_ker0_0 = 5'd10,layer2_ker0_1 = 5'd11,layer2_ker0_2 = 5'd12,layer2_ker1_0 = 5'd13,layer2_ker1_1 = 5'd14,layer2_ker1_2 = 5'd15,finish_state = 5'd16 ;
//============計算iaddr 硬體共用============//
assign iaddr_add1  = iaddr + 12'd1  ;
assign iaddr_add63 = iaddr + 12'd63 ;
assign iaddr_sub63 = iaddr - 12'd63 ;
assign iaddr_add64 = iaddr + 12'd64 ;
assign iaddr_sub64 = iaddr - 12'd64 ;
assign iaddr_sub127 = iaddr - 12'd127 ;
//============比較caddr_wr 硬體共用============//
assign left_top = (caddr_wr == 12'd0); //左上角
assign top = (caddr_wr > 12'd0 && caddr_wr < 12'd63); //中間上面那排
assign right_top = (caddr_wr == 12'd63); //右上角
assign left = (caddr_wr[5:0] == 6'b000000 && caddr_wr >= 12'd64 && caddr_wr <= 12'd3968);
assign caddr_wr_sub63 = caddr_wr - 12'd63;
assign right = (caddr_wr >= 12'd127 && caddr_wr <= 12'd4031 && caddr_wr_sub63[5:0] == 6'b000000);
assign left_bottom = (caddr_wr == 12'd4032); //左下
assign bottom = (caddr_wr > 12'd4032 && caddr_wr < 12'd4095);
assign right_bottom = (caddr_wr == 12'd4095);//右下
//=========================================//

//========================計算寫入資料的address========================//
always@(posedge clk or posedge reset)
begin
    if(reset)
        caddr_wr <= 12'd0;
    // else if(cs == layer0_caddr_wr)  caddr_wr <= counter_0to4095;
    // else if(layer1_ker0_read && counter_4bits == 4'd0) caddr_wr <= counter_0to4095;
    // else if(layer1_ker1_read && counter_4bits == 4'd0) caddr_wr <= counter_0to4095;
    // else if(cs == layer2_ker0_0 || cs ==layer2_ker1_0) caddr_wr <= counter_0to4095;
    else
        caddr_wr <= counter_0to4095;

end

always@(posedge clk or posedge reset)
begin
    if(reset)
        counter_0to4095 <= 12'd0;
    else if(cs == layer0_calculate_k1)
    begin
        if(counter_0to4095 == 12'd4095)
            counter_0to4095 <= 12'd0;
        else
            counter_0to4095 <= counter_0to4095 + 12'd1;
    end
    else if(cs == layer1_ker0_write || cs ==layer1_ker1_write)
    begin
        if(counter_0to4095 == 12'd1023)
            counter_0to4095 <= 12'd0;
        else
            counter_0to4095 <= counter_0to4095 + 12'd1;
    end
    else if(cs == layer2_ker0_2)
    begin
        if(counter_0to4095 == 12'd2046)
            counter_0to4095 <= 12'd1;
        else
            counter_0to4095 <= counter_0to4095 + 12'd2;
    end
    else if(cs == layer2_ker1_2)
    begin
        if(counter_0to4095 == 12'd2047)
            counter_0to4095 <= 12'd0;
        else
            counter_0to4095 <= counter_0to4095 + 12'd2;
    end
    else
        counter_0to4095 <= counter_0to4095;
end
//====================================================================//
//========================計算iaddr========================//
always@(posedge clk or posedge reset)
begin
    if(reset)
        iaddr <= 12'd0;     //0~4095
    else if(cs == layer0_read_data)
    begin
        if(left_top)  //左上角
        begin
            if(counter_4bits == 4'd0)
                iaddr <= 12'd1;    //iaddr=1
            else if(counter_4bits == 4'd1)
                iaddr <= 12'd64;   //iaddr=64
            else if(counter_4bits == 4'd2)
                iaddr <= 12'd65;   //iaddr=65
            else if(counter_4bits == 4'd3)
                iaddr <= 12'd2;    //iaddr=2
            else
                iaddr <= iaddr;
        end
        else if(top) //中間上面那排
        begin
            if(counter_4bits == 4'd0)
                iaddr <= iaddr_add64;     //iaddr=66 67 68..127
            else if(counter_4bits == 4'd1)
                iaddr <= iaddr_sub63;     //iaddr=     3  4 5 63 64
            else
                iaddr <= iaddr;
        end
        else if(right_top) //右上角
        begin
            iaddr <= 12'd0 ;             //iaddr = 0
        end
        else if(left) //左邊那排 64 128 ...3968
        begin
            if(counter_4bits == 4'd0)
                iaddr <= iaddr_add1;     //iaddr=1
            else if(counter_4bits == 4'd1)
                iaddr <= iaddr_add63;    //iaddr=64
            else if(counter_4bits == 4'd2)
                iaddr <= iaddr_add1;     //iaddr=65
            else if(counter_4bits == 4'd3)
                iaddr <= iaddr_add63;    //iaddr=128
            else if(counter_4bits == 4'd4)
                iaddr <= iaddr_add1;    //iaddr=129
            else if(counter_4bits == 4'd5)
                iaddr <= iaddr_sub127;    //iaddr=2  給中間那塊用
            else
                iaddr <= iaddr;
        end
        else if(right) //右邊那排 127 192 ...4031
        begin
            iaddr <= iaddr; //給左邊那排用
        end
        else if(left_bottom)  //左下角
        begin
            if(counter_4bits == 4'd0)
                iaddr <= 12'd3969;     //iaddr=3969
            else if(counter_4bits == 4'd1)
                iaddr <= 12'd4032;    //iaddr=4032
            else if(counter_4bits == 4'd2)
                iaddr <= 12'd4033;     //iaddr=4033
            else if(counter_4bits == 4'd3)
                iaddr <= 12'd3970;    //iaddr=3970
            else
                iaddr <= iaddr;
        end
        else if(bottom) //下面那排
        begin
            if(counter_4bits == 4'd0)
                iaddr <= iaddr_add64;     //iaddr= 4034 4035...4095
            else if(counter_4bits == 4'd1)
                iaddr <= iaddr_sub63;     //iaddr= 3970 3910...4031
            else
                iaddr <= iaddr;
        end
        else if(right_bottom)
            iaddr <= iaddr;
        else                    //中間那塊
        begin
            if(counter_4bits == 4'd0)
                iaddr <= iaddr_add64;     //iaddr=66  67   127
            else if(counter_4bits == 4'd1)
                iaddr <= iaddr_add64;    //iaddr=130  131  191
            else if(counter_4bits == 4'd2)
                iaddr <= iaddr_sub127;     //iaddr=   3    64
            else
                iaddr <= iaddr;
        end
    end


end
//====================================================================//
//=================狀態機=================//
always@(posedge clk or posedge reset)
begin
    if(reset)
        cs <= idle;
    else
        cs <= ns;
end

always@(*)
begin
    if(cs == idle)
        ns = busy_sig;
    else if(cs == busy_sig)
        ns = layer0_read_data;
    else if(cs == layer0_read_data )
    begin
        if(counter_4bits == counter_4bits_set)
            ns = layer0_calculate_k0;
        else
            ns = layer0_read_data;
    end
    else if(cs == layer0_calculate_k0)
        ns = layer0_calculate_k1;
    else if(cs == layer0_calculate_k1)
        ns = layer0_caddr_wr;
    else if(cs ==layer0_caddr_wr)
    begin
        if(right_bottom)
            ns = layer1_ker0_read;
        else
            ns = layer0_read_data;
    end
    else if(cs == layer1_ker0_read)
    begin
        if(counter_4bits == 4'd4)
            ns = layer1_ker0_write;
        else
            ns = layer1_ker0_read;
    end
    else if(cs == layer1_ker0_write)
    begin
        if(caddr_wr == 12'd1023)
            ns = layer1_ker1_read;
        else
            ns = layer1_ker0_read;
    end
    else if(cs == layer1_ker1_read)
    begin
        if(counter_4bits == 4'd4)
            ns = layer1_ker1_write;
        else
            ns = layer1_ker1_read;
    end
    else if(cs == layer1_ker1_write)
    begin
        if(caddr_wr == 12'd1023)
            ns = layer2_ker0_0;
        else
            ns = layer1_ker1_read;
    end
    else if(cs == layer2_ker0_0)
        ns = layer2_ker0_1;
    else if(cs == layer2_ker0_1)
        ns = layer2_ker0_2;
    else if(cs == layer2_ker0_2)
    begin
        if(caddr_rd == 12'd1023)
            ns = layer2_ker1_0;
        else
            ns = layer2_ker0_0;
    end
    else if(cs == layer2_ker1_0)
        ns = layer2_ker1_1;
    else if(cs == layer2_ker1_1)
        ns = layer2_ker1_2;
    else if(cs == layer2_ker1_2)
    begin
        if(caddr_rd == 12'd1023)
            ns = finish_state;
        else
            ns = layer2_ker1_0;
    end
    else if(finish_state)
        ns = finish_state;

    else
        ns = cs;
end
//=======================================//
//=================counter_4bits=================//
always@(posedge clk or posedge reset)
begin
    if(reset)
        counter_4bits <= 4'd0;
    else if(cs == layer0_read_data)
    begin
        if(counter_4bits == counter_4bits_set )
            counter_4bits <= 4'd0;
        else
            counter_4bits <= counter_4bits + 4'd1;
    end
    else if(cs == layer1_ker0_read || cs == layer1_ker1_read)
    begin
        if(counter_4bits == 4'd4)
            counter_4bits <= 4'd0;
        else
            counter_4bits <= counter_4bits + 4'd1;
    end
end

always@(*)
begin
    //if(reset) counter_4bits_set <= 4'd0;
    if(cs == layer0_read_data)
    begin
        if(left_top || left_bottom)
            counter_4bits_set = 4'd3;
        else if(top || bottom)
            counter_4bits_set = 4'd1;
        else if(right_top || right || right_bottom)
            counter_4bits_set = 4'd0;
        else if(left)
            counter_4bits_set = 4'd5;
        else
            counter_4bits_set = 4'd2;
    end
    else
        counter_4bits_set = 4'd0;
end
//=======================================//

//================layer0 讀資料================//
always@(posedge clk or posedge reset)
begin
    if(reset)
        conv_reg0 <= 20'd0;
    else if(cs == layer0_read_data)
    begin
        if(left_top || left_bottom || left || top || right_top)
            conv_reg0 <= 20'd0;
        else if(right || right_bottom)
            conv_reg0 <= conv_reg1;
        else if(bottom)
        begin
            if(counter_4bits == 4'd0)
                conv_reg0 <= conv_reg1;
            else
                conv_reg0 <= conv_reg0;
        end
        else
        begin
            if(counter_4bits == 4'd0)
                conv_reg0 <= conv_reg1;
            else
                conv_reg0 <= conv_reg0;
        end

    end
    else if(cs == layer1_ker0_read || cs == layer1_ker1_read)                //處理layer1比大小
    begin
        if(counter_4bits == 4'd0)
            conv_reg0 <= 20'd0;
        else if(counter_4bits == 4'd1)
            conv_reg0 <= cdata_rd;
        else if(counter_4bits == 4'd2 || counter_4bits == 4'd3 || counter_4bits == 4'd4)
        begin
            if(cdata_rd > conv_reg0)
                conv_reg0 <= cdata_rd;
            else
                conv_reg0 <= conv_reg0;
        end
    end
    else if(cs == layer2_ker0_1 || cs == layer2_ker1_1)
        conv_reg0 <= cdata_rd;
    else
        conv_reg0 <= conv_reg0;
end

always@(posedge clk or posedge reset)
begin
    if(reset)
        conv_reg1 <= 20'd0;
    else if(cs == layer0_read_data)
    begin
        if(left_top || top || right_top)
            conv_reg1 <= 20'd0;
        else if(left || left_bottom)
        begin
            if(counter_4bits == 4'd0)
                conv_reg1 <= idata;
            else
                conv_reg1 <= conv_reg1;
        end
        else if(right || right_bottom)
            conv_reg1 <= conv_reg2;
        else            //中間跟bottom
        begin
            if(counter_4bits == 4'd0)
                conv_reg1 <= conv_reg2;
            else
                conv_reg1 <= conv_reg1;
        end

    end
end

always @(posedge clk or posedge reset)
begin
    if(reset)
        conv_reg2 <= 20'd0;
    else if(cs == layer0_read_data)
    begin
        if(left_top || top || right_top || right || right_bottom)
            conv_reg2 <= 20'd0;
        else if(left || left_bottom)
        begin
            if(counter_4bits == 4'd0)
                conv_reg2 <= 20'd0;
            else if(counter_4bits == 4'd1)
                conv_reg2 <= idata;
            else
                conv_reg2 <= conv_reg2;
        end

        else  //中間跟bottom
        begin
            if(counter_4bits == 4'd0)
                conv_reg2 <= idata;
            else
                conv_reg2 <= conv_reg2;
        end
    end
end

always @(posedge clk or posedge reset)
begin
    if(reset)
        conv_reg3 <= 20'd0;
    else if(cs == layer0_read_data)
    begin
        if(left_top || left || left_bottom)
            conv_reg3 <= 20'd0;
        else if(right_top || right || right_bottom)
            conv_reg3 <= conv_reg4;
        else  //中間跟bottom，top
        begin
            if(counter_4bits == 4'd0)
                conv_reg3 <= conv_reg4;
            else
                conv_reg3 <= conv_reg3;
        end
    end
end

always @(posedge clk or posedge reset)
begin
    if(reset)
        conv_reg4 <= 20'd0;
    else if(cs == layer0_read_data)
    begin
        if(left_top)
        begin
            if(counter_4bits == 4'd0)
                conv_reg4 <= idata;
            else
                conv_reg4 <= conv_reg4;
        end
        else if(top || bottom)
        begin
            if(counter_4bits == 4'd0)
                conv_reg4 <= conv_reg5;
            else
                conv_reg4 <= conv_reg4;
        end
        else if(right_top || right || right_bottom)
            conv_reg4 <= conv_reg5;
        else if(left || left_bottom)
        begin
            if(counter_4bits == 4'd0 || counter_4bits == 4'd1)
                conv_reg4 <= 20'd0;
            else if(counter_4bits == 4'd2)
                conv_reg4 <= idata;
            else
                conv_reg4 <= conv_reg4;
        end

        else  //中間跟bottom，top
        begin
            if(counter_4bits == 4'd0)
                conv_reg4 <= conv_reg5;
            else
                conv_reg4 <= conv_reg4;
        end
    end
end

always @(posedge clk or posedge reset)
begin
    if(reset)
        conv_reg5 <= 20'd0;
    else if(cs == layer0_read_data)
    begin
        if(left_top)
        begin
            if(counter_4bits == 4'd0)
                conv_reg5 <= 20'd0;
            else if(counter_4bits == 4'd1)
                conv_reg5 <= idata;
            else
                conv_reg5 <= conv_reg5;
        end
        else if(top)
        begin
            if(counter_4bits == 4'd0)
                conv_reg5 <= idata;
            else
                conv_reg5 <= conv_reg5;
        end
        else if(right_top || right || right_bottom)
            conv_reg5 <= 20'd0;
        else if(left || left_bottom)
        begin
            if(counter_4bits == 4'd0 || counter_4bits == 4'd1 || counter_4bits == 4'd2)
                conv_reg5 <= 20'd0;
            else if(counter_4bits == 4'd3)
                conv_reg5 <= idata;
            else
                conv_reg5 <= conv_reg5;
        end
        else     //中間跟bottom
        begin
            if(counter_4bits == 4'd0)
                conv_reg5 <= 20'd0;
            else if(counter_4bits == 4'd1)
                conv_reg5 <= idata;
            else
                conv_reg5 <= conv_reg5;
        end
    end
end

always @(posedge clk or posedge reset)
begin
    if(reset)
        conv_reg6 <= 20'd0;
    else if(cs == layer0_read_data)
    begin
        if(left_top || left || left_bottom || bottom || right_bottom)
            conv_reg6 <= 20'd0;
        else if(top)
        begin
            if(counter_4bits == 4'd0)
                conv_reg6 <= conv_reg7;
            else
                conv_reg6 <= conv_reg6;
        end
        else if(right_top || right)
            conv_reg6 <= conv_reg7;
        else
        begin
            if(counter_4bits == 4'd0)
                conv_reg6 <= conv_reg7;
            else
                conv_reg6 <= conv_reg6;
        end
    end
end

always @(posedge clk or posedge reset)
begin
    if(reset)
        conv_reg7 <= 20'd0;
    else if(cs == layer0_read_data)
    begin
        if(left_top)
        begin
            if(counter_4bits == 4'd0 || counter_4bits == 4'd1)
                conv_reg7 <= 20'd0;
            else if(counter_4bits == 4'd2)
                conv_reg7 <= idata;
            else
                conv_reg7 <= conv_reg7;
        end
        else if(right_top || right)
            conv_reg7 <= conv_reg8;
        else if(left)
        begin
            if(counter_4bits <= 4'd3)
                conv_reg7 <= 20'd0;
            else if(counter_4bits == 4'd4)
                conv_reg7 <= idata;
            else
                conv_reg7 <= conv_reg7;
        end
        else if(left_bottom || bottom || right_bottom)
            conv_reg7 <= 20'd0;
        else //top,middle
        begin
            if(counter_4bits == 4'd0)
                conv_reg7 <= conv_reg8;
            else
                conv_reg7 <= conv_reg7;
        end
    end
end

always @(posedge clk or posedge reset)
begin
    if(reset)
        conv_reg8 <= 20'd0;
    else if(cs == layer0_read_data)
    begin
        if(left_top)
        begin
            if(counter_4bits == 4'd0 || counter_4bits == 4'd1 || counter_4bits == 4'd2)
                conv_reg8 <= 20'd0;
            else if(counter_4bits == 4'd3)
                conv_reg8 <= idata;
            else
                conv_reg8 <= conv_reg8;
        end
        else if(top)
        begin
            if(counter_4bits == 4'd0)
                conv_reg8<= 20'd0;
            else
                conv_reg8 <= idata;
        end
        else if(right_top || right || right_bottom || left_bottom || bottom)
            conv_reg8 <= 20'd0;
        else if(left)
        begin
            if(counter_4bits <= 4'd4)
                conv_reg8 <= 20'd0;
            else
                conv_reg8 <= idata;
        end
        else
        begin
            if(counter_4bits == 4'd0 || counter_4bits == 4'd1)
                conv_reg8 <= 20'd0;
            else
                conv_reg8 <= idata;
        end
    end
end
//===================================================================//

//================layer0計算 convolution RELU 四捨五入================//

always @(*)
begin
    if(cs == layer0_calculate_k0)
        {k0,k1,k2,k3,k4,k5,k6,k7,k8,bias} = {ker00,ker01,ker02,ker03,ker04,ker05,ker06,ker07,ker08,ker0_bias};
    else if(cs == layer0_calculate_k1)
        {k0,k1,k2,k3,k4,k5,k6,k7,k8,bias} = {ker10,ker11,ker12,ker13,ker14,ker15,ker16,ker17,ker18,ker1_bias};
    else
        {k0,k1,k2,k3,k4,k5,k6,k7,k8,bias} = {20'd0,20'd0,20'd0,20'd0,20'd0,20'd0,20'd0,20'd0,20'd0,20'd0};
end
assign a0 = k0 * conv_reg0;
assign a1 = k1 * conv_reg1;
assign a2 = k2 * conv_reg2;
assign a3 = k3 * conv_reg3;
assign a4 = k4 * conv_reg4;
assign a5 = k5 * conv_reg5;
assign a6 = k6 * conv_reg6;
assign a7 = k7 * conv_reg7;
assign a8 = k8 * conv_reg8;
// assign wire_42bits = (a0+a1)+(a2+a3)+(a4+a5)+(a6+a7)+(a8+bias);
assign wire_42bits = a0+a1+a2+a3+a4+a5+a6+a7+a8+bias;



assign wire_20bits = wire_42bits[35:16] + wire_42bits[15];
always @(posedge clk or posedge reset )
begin
    if(reset)
        cdata_wr <= 20'd0;
    else if(cs == layer0_calculate_k0 || cs == layer0_calculate_k1)
    begin
        if(wire_20bits[19] == 1'b1)
            cdata_wr <= 20'd0;
        else
            cdata_wr <= wire_20bits;
    end
    else if(cs == layer1_ker0_write || cs == layer1_ker1_write)
        cdata_wr <= conv_reg0;
    else if(cs == layer2_ker0_2 || layer2_ker1_2)
        cdata_wr <= conv_reg0;
    else
        cdata_wr <= 20'd0;
end

//===================================================================//

//=================csel=================//
always@(posedge clk or posedge reset)
begin
    if (reset)
        csel <= 3'b0;
    else if (cs == layer0_calculate_k0 || ( cs == layer1_ker0_read  && counter_4bits == 4'd0) )
        csel <= 3'b001;
    else if(cs == layer0_calculate_k1 || ( cs == layer1_ker1_read  && counter_4bits == 4'd0) )
        csel <= 3'b010;
    else if( cs == layer1_ker0_write || cs == layer2_ker0_0)
        csel <= 3'b011;
    else if(cs == layer1_ker1_write || cs == layer2_ker1_0)
        csel <= 3'b100;
    else if(cs == layer2_ker0_2 || cs == layer2_ker1_2)
        csel <= 3'b101;
    else
        csel <= csel;
end
//======================================//

//=================cwr=================//
always@(posedge clk or posedge reset)
begin
    if (reset)
        cwr <= 1'b0;
    else if (cs == layer0_calculate_k0 || cs == layer0_calculate_k1 || cs == layer1_ker0_write || cs == layer1_ker1_write  )
        cwr <= 1'b1;
    else if(cs == layer2_ker0_2 || cs == layer2_ker1_2)
        cwr <= 1'b1;
    else
        cwr <= 1'b0;
end
//======================================//
//=================crd=================//
always@(posedge clk or posedge reset)
begin
    if (reset)
        crd <= 1'b0;
    else if(right_bottom)
        crd <= 1'b1;
    else if(cs == layer1_ker0_read || cs == layer1_ker1_read)
    begin
        if(counter_4bits == 4'd4)
            crd <= 1'b0;
        else
            crd <= 1'b1;
    end
    else if(cs == layer2_ker0_0 || cs == layer2_ker1_0 )
        crd <= 1'b1;
    else
        crd <= 1'b0;
end
//======================================//

//=================caddr_rd=================//
always@(posedge clk or posedge reset)
begin
    if (reset)
        caddr_rd <= 12'b0;
    else if(cs == layer1_ker0_read || cs == layer1_ker1_read)
    begin
        if(counter_4bits == 4'd0)
            caddr_rd <= caddr_rd;
        else if(counter_4bits == 4'd1)
            caddr_rd <= caddr_rd + 12'd1;
        else if(counter_4bits == 4'd2)
            caddr_rd <= caddr_rd + 12'd63;
        else if(counter_4bits == 4'd3)
            caddr_rd <= caddr_rd + 12'd1;
        else if(counter_4bits == 4'd4)
        begin
            if(caddr_rd[6:0] == 7'b1111111)
                caddr_rd <= caddr_rd + 12'd1;
            else
                caddr_rd <= caddr_rd - 12'd63;
        end
    end
    else if(cs == layer2_ker0_2 || cs == layer2_ker1_2)
    begin
        if(caddr_rd == 12'd1023)
            caddr_rd <= 12'd0;
        else
            caddr_rd <= caddr_rd + 12'd1;
    end
    else
        caddr_rd <= caddr_rd;
end
//======================================//

//=================busy=================//
always@(posedge clk or posedge reset)
begin
    if (reset)
        busy <= 1'b0;
    else if (ready)
        busy <= 1'b1;
    else if(cs == finish_state)
        busy <= 1'd0;
    else
        busy <= busy;
end
//======================================//
endmodule
