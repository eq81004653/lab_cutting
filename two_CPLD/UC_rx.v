//recieve data in FM from 9.5Hz to 4Hz 

module UC_rx(clk,out,set,out_1,out_2);

input clk;	//clk 40MHz
input set;
output[4:0]out;	//D5-D1
//reg[4:0] out;

reg [4:0]Dout=5'd25;
output out_1,out_2;

reg rx_clk;	//clk for recieve data(about 76Hz=13ms), data send at 4Hz=9.6 of rx_clk

reg[19:0] rx_clk_cnt;

assign out=Dout[4:0];
assign out_1=set;
assign out_2=rx_clk;

reg[11:0] data;	//data receive
reg[4:0] data_cnt;
reg[4:0] cnt;
reg [1:0]RX_state=2'd0;
reg [3:0]position_rx=4'd0;
reg [11:0]search=0;
reg ready;
reg [3:0]count=4'd0;

reg [9:0]count_stste=10'd0;


always@(posedge clk)
begin
	//out[4]=set;
	
	rx_clk_cnt<=(rx_clk_cnt==20'd69444)?20'd0:rx_clk_cnt+20'd1;
	rx_clk<=(rx_clk_cnt==20'd1)?1'b1:1'b0;
	
	
	if(rx_clk==1'd1)begin
///////////////////////////////////	
		if(RX_state==2'd0)begin
			ready<=1'd0;
			if(set==1'd1)begin
				count<=count+4'd1;
				if(count==4'd8)begin
					RX_state<=2'd1;
					position_rx<=4'd0;
				end
			end
			else begin
				count<=4'd0;
				position_rx<=4'd0;
				RX_state<=2'd0;
			end
				
		end
//////////////////////////////		
		else if(RX_state==2'd1)
		begin
			ready<=1'd0;
			count<=count+4'd1;
			if(count==4'd4)begin
				position_rx<=position_rx+4'd1;
				search[position_rx]<=set;
			end
			
			/*if ((search[position_rx]==search[position_rx-4'd1])&&(search[position_rx-4'd1]==search[position_rx-4'd2]))
			begin
				count<=4'd0;
				RX_state<=2'd0;
				position_rx<=4'd0;
				ready<=1'd0;
			end
			
			else
			begin*/
				if(position_rx==4'd12)
				begin
					RX_state<=2'd2;
					data<=search;
					count<=count;
				end
//			end
			
			
		end
//////////////////////////////
		else if(RX_state==2'd2)
		begin
		count<=count+4'd1;
			if(rx_clk==1'd1&&set==1'd0&&count==4'd8)
			begin
				ready<=1'd1;
				position_rx<=4'd0;
				RX_state<=2'd3;
				count<=4'd0;
			end
			
		end
/////////////////////////////////
		else if(RX_state==2'd3)
		begin
			count_stste<=count_stste+5'd1;
			
			if(count_stste==10'd192)
			begin
				ready<=1'd1;
				position_rx<=4'd0;
				RX_state<=2'd0;
				count<=4'd0;
			end
		
		end
		
////////////////////////////////
		else 
		begin
			count<=4'd0;
			RX_state<=2'd0;
			position_rx<=4'd0;
			ready<=1'd0;
		end
	end
	
	case(data)
		12'b010101010101:begin  Dout[4:0]<=(ready)?5'd0:Dout[4:0]; end			//30kHz
		12'b010101010110:begin  Dout[4:0]<=(ready)?5'd1:Dout[4:0]; end			//30.5kHz
		12'b010101011001:begin  Dout[4:0]<=(ready)?5'd2:Dout[4:0]; end			//31kHz
		12'b010101011010:begin  Dout[4:0]<=(ready)?5'd3:Dout[4:0]; end			//31.5kHz
		12'b010101100101:begin  Dout[4:0]<=(ready)?5'd4:Dout[4:0]; end			//32kHz
		12'b010101100110:begin  Dout[4:0]<=(ready)?5'd5:Dout[4:0]; end			//32.5kHz
		12'b010101101001:begin  Dout[4:0]<=(ready)?5'd6:Dout[4:0]; end			//33kHz
		12'b010101101010:begin  Dout[4:0]<=(ready)?5'd7:Dout[4:0]; end			//33.5kHz
		12'b010110010101:begin  Dout[4:0]<=(ready)?5'd8:Dout[4:0]; end			//34kHz
		12'b010110010110:begin  Dout[4:0]<=(ready)?5'd9:Dout[4:0]; end			//34.5kHz
		12'b010110011001:begin  Dout[4:0]<=(ready)?5'd10:Dout[4:0]; end		//35kHz
		12'b010110011010:begin  Dout[4:0]<=(ready)?5'd11:Dout[4:0]; end		//35.5kHz
		12'b010110100101:begin  Dout[4:0]<=(ready)?5'd12:Dout[4:0]; end		//36kHz
		12'b010110101001:begin  Dout[4:0]<=(ready)?5'd13:Dout[4:0]; end		//36.5kHz
		12'b010110101010:begin  Dout[4:0]<=(ready)?5'd14:Dout[4:0]; end		//37kHz
		12'b011001010101:begin  Dout[4:0]<=(ready)?5'd15:Dout[4:0]; end		//37.5kHz
		12'b011001010110:begin  Dout[4:0]<=(ready)?5'd16:Dout[4:0]; end		//38kHz
		12'b011001011001:begin  Dout[4:0]<=(ready)?5'd17:Dout[4:0]; end		//38.5kHz
		12'b011001011010:begin  Dout[4:0]<=(ready)?5'd18:Dout[4:0]; end		//39kHz
		12'b011001100101:begin  Dout[4:0]<=(ready)?5'd19:Dout[4:0]; end		//39.5kHz
		12'b011001100110:begin  Dout[4:0]<=(ready)?5'd20:Dout[4:0]; end		//40kHz
		12'b011001101001:begin  Dout[4:0]<=(ready)?5'd21:Dout[4:0]; end		//RUN
		12'b011001101010:begin  Dout[4:0]<=(ready)?5'd22:Dout[4:0]; end		//STOP
		12'b011010010101:begin  Dout[4:0]<=(ready)?5'd23:Dout[4:0]; end		//SWEEP
		12'b011010010110:begin  Dout[4:0]<=(ready)?5'd24:Dout[4:0]; end		//LOCK
	default:	begin  Dout[4:0]<=Dout[4:0]; end
	endcase
		
	
		 
end 	



endmodule
