  module LCD(clk50M,out0,out0_1,out1,out1_1,out2,out2_1,out3,out3_1,cs_n,cs_n1,out_clk,out_clk_1O5MHz,position_out,INT,PD,botton,botton_out,botton2,sweep,run,OFF,LOCK,freq_cho,current,current_flag,clk20MHz,TX_choose);
input clk50M,clk20MHz;
input [10:0]current;
inout reg out0=0,out1=0,out2=0,out3=0;
input botton,botton2,current_flag;
output cs_n1,position_out,botton_out,sweep,run,OFF,LOCK; 
output reg[3:0]freq_cho;
inout out0_1,out1_1,out2_1,out3_1;
input [5:0]TX_choose;



reg sweep,run,OFF,LOCK;

reg alw=1;
reg botton_delay;
reg botton2_delay;

reg [4:0]botton2_counter=5'd0;



reg clk_1O5MHz;

reg [3:0] counter;

reg [9:0] clk_count;

wire clk_1O5Hz;
assign clk_1O5Hz=clk_1O5Hz_count[22];

reg [23:0] clk_1O5Hz_count;

always @(negedge clk50M)begin
 counter<=counter+1'b1;
 clk_1O5MHz=counter[2];
 
 clk_1O5Hz_count<=clk_1O5Hz_count+1'b1;
 
 if(cs_ready==0)begin out_clk_1O5MHz<=clk_1O5MHz;end
 else begin out_clk_1O5MHz<=0;end
  
end


//reg [25:0] count_20MHz;
//always @(posedge clk20MHz) begin count_20MHz<=count_20MHz+1'b1; end

output wire out_clk;
assign out_clk=out_clk_1O5MHz;
output reg out_clk_1O5MHz;

output reg cs_n=1,INT=1,PD=1;

assign cs_n1=cs_n;

assign out0_1=out0;
assign out1_1=out1;
assign out2_1=out2;
assign out3_1=out3;


assign botton_out=botton;



reg [3:0]state=0;
reg signed [9:0]position;
reg signed [9:0]position1;
reg signed [9:0]position2;
reg signed [9:0]position3;

reg [279:0]data;
reg [279:0]int;
reg cs_ready=0;

 
reg[19:0]count=20'd0;



reg [3:0]botton2_jump;
reg [3:0]botton_jump;

reg botton2_right;
reg botton_right;

reg [1:0]choice;





reg [39:0]readdata;

reg[15:0]readdata_X;
reg[15:0]readdata_Y;
reg[15:0]readdata_true_Y;
reg[15:0]readdata_true_X;

reg[10:0]read_current;
reg[10:0]map_current;
reg[15:0]true_map_current[10:0];
reg[14:0]shift_map_current;



always @(negedge clk50M)begin

	readdata_X<=readdata[15:0];
	readdata_Y<=readdata[31:16];
	readdata_true_X[15:0]<={readdata_X[7:0],readdata_X[15:8]};
	readdata_true_Y[15:0]<={readdata_Y[7:0],readdata_Y[15:8]};


	if(current_flag==1'b1)
	begin 
		read_current<=current;
		map_current<={4'd0,11'd420-((read_current-11'd256)+((read_current-11'd256)>>4)+11'd40)};
		
	end
	
	else begin
		read_current<=read_current;
		map_current<=map_current;
	end
	
	
	
	shift_map_current<={map_current,4'd0};
	true_map_current[botton2_counter]<={shift_map_current[7:0],1'b0,shift_map_current[14:8]};


end



reg [3:0]sweep_count;
reg current_flag_delay;


always @(posedge clk20MHz) begin 
	current_flag_delay<=current_flag;
	sweep_count<=(sweep)?5'd0:(sweep_count<=4'd12&&current_flag==1'b1&&current_flag_delay==1'b0)?sweep_count+4'd1:sweep_count; 
	botton2_counter<=(sweep)?5'd0:(sweep_count>=4'd2&&botton2_counter<=5'd9&&current_flag==1'b1&&current_flag_delay==1'b0&&TX_choose>=6'd2)?TX_choose[4:0]-5'd2:botton2_counter;

end


reg[25:0]time_counter;
reg[3:0]count_point;






always @(negedge clk_1O5MHz) begin
   

////////////////////////按鍵顯示////////////////////////////////
	if({9'd0,choice[0]}+time_counter>=10'd1&&{9'd0,choice[0]}+time_counter<=26'd3194304)
		begin
		time_counter<=time_counter+26'd1;
		
		if(choice[0]&&count_point<4'd4) count_point<=count_point+4'd1;
		else count_point<=count_point;
			
		end
		
	else
		begin
		time_counter<=26'd0;
		count_point<=4'd0;
		end
	
	

	
	readdata[39:0]<={readdata[38:0],out1};
	
	/////////////////////////////////////////RUN//////////////////////////////////
//	if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd210&&readdata_true_X>=16'd84&&readdata_true_Y<=16'd871&&readdata_true_Y>=16'd768&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd210&&readdata_true_X>=16'd84&&readdata_true_Y<=16'd871&&readdata_true_Y>=16'd768&&readdata[39:32]==8'h42))	
	if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd210&&readdata_true_X>=16'd84&&readdata_true_Y<=16'd871&&readdata_true_Y>=16'd768&&readdata[39:32]==8'h42)    
		begin run<=1'd1;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd0;choice<=2'd1;end
	/////////////////////////////////////////OFF//////////////////////////////////
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd210&&readdata_true_X>=16'd75&&readdata_true_Y<=16'd643&&readdata_true_Y>=16'd540&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd210&&readdata_true_X>=16'd75&&readdata_true_Y<=16'd643&&readdata_true_Y>=16'd545&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd210&&readdata_true_X>=16'd75&&readdata_true_Y<=16'd643&&readdata_true_Y>=16'd545&&readdata[39:32]==8'h42)
		begin run<=1'd0;OFF<=1'd1;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd0;choice<=2'd1;end
	/////////////////////////////////////////SWEEP//////////////////////////////////	
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd210&&readdata_true_X>=16'd75&&readdata_true_Y<=16'd415&&readdata_true_Y>=16'd312&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd210&&readdata_true_X>=16'd75&&readdata_true_Y<=16'd415&&readdata_true_Y>=16'd312&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd210&&readdata_true_X>=16'd75&&readdata_true_Y<=16'd415&&readdata_true_Y>=16'd312&&readdata[39:32]==8'h42)	
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd1;LOCK<=1'd0;freq_cho<=4'd0;choice<=2'd1;end
	/////////////////////////////////////////LOCK//////////////////////////////////	
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd210&&readdata_true_X>=16'd75&&readdata_true_Y<=16'd187&&readdata_true_Y>=16'd84&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd210&&readdata_true_X>=16'd75&&readdata_true_Y<=16'd187&&readdata_true_Y>=16'd84&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd210&&readdata_true_X>=16'd75&&readdata_true_Y<=16'd187&&readdata_true_Y>=16'd84&&readdata[39:32]==8'h42)
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd1;freq_cho<=4'd0;choice<=2'd1;end		
	/////////////////////////////////////////30k//////////////////////////////////	
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd348&&readdata_true_X>=16'd311&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd348&&readdata_true_X>=16'd311&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd348&&readdata_true_X>=16'd311&&readdata[39:32]==8'h42)
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd1;choice<=2'd1;end	
	/////////////////////////////////////////31k//////////////////////////////////	
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd412&&readdata_true_X>=16'd372&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd412&&readdata_true_X>=16'd372&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd412&&readdata_true_X>=16'd372&&readdata[39:32]==8'h42)	
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd2;choice<=2'd1;end
	/////////////////////////////////////////32k//////////////////////////////////	
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd468&&readdata_true_X>=16'd432&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd468&&readdata_true_X>=16'd432&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd468&&readdata_true_X>=16'd432&&readdata[39:32]==8'h42)	
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd3;choice<=2'd1;end		
	/////////////////////////////////////////33k//////////////////////////////////	
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd523&&readdata_true_X>=16'd492&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd523&&readdata_true_X>=16'd492&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd523&&readdata_true_X>=16'd492&&readdata[39:32]==8'h42)	
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd4;choice<=2'd1;end		
	///////////////////////////////////////////34k//////////////////////////////////	
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd587&&readdata_true_X>=16'd553&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd587&&readdata_true_X>=16'd553&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd587&&readdata_true_X>=16'd553&&readdata[39:32]==8'h42)	
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd5;choice<=2'd1;end
	///////////////////////////////////////////35k//////////////////////////////////	
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd652&&readdata_true_X>=16'd616&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd652&&readdata_true_X>=16'd616&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd652&&readdata_true_X>=16'd616&&readdata[39:32]==8'h42)	
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd6;choice<=2'd1;end	
	///////////////////////////////////////////36k//////////////////////////////////	
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd707&&readdata_true_X>=16'd670&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd707&&readdata_true_X>=16'd670&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd707&&readdata_true_X>=16'd670&&readdata[39:32]==8'h42)	
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd7;choice<=2'd1;end
	///////////////////////////////////////////37k//////////////////////////////////	
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd768&&readdata_true_X>=16'd736&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd768&&readdata_true_X>=16'd736&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd768&&readdata_true_X>=16'd736&&readdata[39:32]==8'h42)	
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd8;choice<=2'd1;end	
	///////////////////////////////////////////38k//////////////////////////////////	
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd816&&readdata_true_X>=16'd791&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd816&&readdata_true_X>=16'd791&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd816&&readdata_true_X>=16'd791&&readdata[39:32]==8'h42)	
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd9;choice<=2'd1;end		
	///////////////////////////////////////////39k//////////////////////////////////	
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd880&&readdata_true_X>=16'd848&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd880&&readdata_true_X>=16'd848&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd880&&readdata_true_X>=16'd848&&readdata[39:32]==8'h42)	
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd10;choice<=2'd1;end
	//////////////////////////////////////////40k//////////////////////////////////	
//	else if(((count>=20'd43&&count<=20'd53)&&readdata_true_X<=16'd940&&readdata_true_X>=16'd909&&readdata[39:32]==8'h42)||((count>=20'd73&&count<=20'd83)&&readdata_true_X<=16'd940&&readdata_true_X>=16'd909&&readdata[39:32]==8'h42))	
	else if(((count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd203&&count<=20'd208)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))&&readdata_true_X<=16'd940&&readdata_true_X>=16'd909&&readdata[39:32]==8'h42)	
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd11;choice<=2'd1;end

	
	else
		begin run<=1'd0;OFF<=1'd0;sweep<=1'd0;LOCK<=1'd0;freq_cho<=4'd0;choice<=2'd0;end  
	
	
	
	
	
	if(state==4'd0) begin
//		if({botton_delay,botton_right}==2'b01)begin
		if(alw==1)begin
			state<=4'd1;
			cs_n<=1;
			position<=10'd279;
			position1<=10'd278;
			position2<=10'd277;
			position3<=10'd276;
			
		end	  
	end
	
	else if(state==4'd1)begin
	
		if(count>20'd158 && botton2_counter==5'd0)begin
			state<=4'd0;
			cs_n<=1;
			count<=0;
			out0<=0;
			out1<=0;
			out2<=0;
			out3<=0;
			clk_count<=0;end
			
		else if((count>20'd183 && botton2_counter==5'd1)||(count<20'd159 && botton2_counter==5'd1))begin
			state<=4'd0;
			cs_n<=1;
			count<=20'd159;
			out0<=0;
			out1<=0;
			out2<=0;
			out3<=0;
			clk_count<=0;end
			
		else if((count>20'd208 && botton2_counter==5'd2)||(count<20'd184 && botton2_counter==5'd2))begin
			state<=4'd0;
			cs_n<=1;
			count<=20'd184;
			out0<=0;
			out1<=0;
			out2<=0;
			out3<=0;
			clk_count<=0;end
			
			
		else if((count>20'd234 && botton2_counter==5'd3)||(count<20'd209 && botton2_counter==5'd3))begin
			state<=4'd0;
			cs_n<=1;
			count<=20'd209;
			out0<=0;
			out1<=0;
			out2<=0;
			out3<=0;
			clk_count<=0;end
		else if((count>20'd259 && botton2_counter==5'd4)||(count<20'd235 && botton2_counter==5'd4))begin
			state<=4'd0;
			cs_n<=1;
			count<=20'd235;
			out0<=0;
			out1<=0;
			out2<=0;
			out3<=0;
			clk_count<=0;end
		else if((count>20'd285 && botton2_counter==5'd5)||(count<20'd260 && botton2_counter==5'd5))begin
			state<=4'd0;
			cs_n<=1;
			count<=20'd260;
			out0<=0;
			out1<=0;
			out2<=0;
			out3<=0;
			clk_count<=0;end
		else if((count>20'd311 && botton2_counter==5'd6)||(count<20'd286 && botton2_counter==5'd6))begin
			state<=4'd0;
			cs_n<=1;
			count<=20'd286;
			out0<=0;
			out1<=0;
			out2<=0;
			out3<=0;
			clk_count<=0;end
		else if((count>20'd337 && botton2_counter==5'd7)||(count<20'd312 && botton2_counter==5'd7))begin
			state<=4'd0;
			cs_n<=1;
			count<=20'd312;
			out0<=0;
			out1<=0;
			out2<=0;
			out3<=0;
			clk_count<=0;end
		else if((count>20'd363 && botton2_counter==5'd8)||(count<20'd338 && botton2_counter==5'd8))begin
			state<=4'd0;
			cs_n<=1;
			count<=20'd338;
			out0<=0;
			out1<=0;
			out2<=0;
			out3<=0;
			clk_count<=0;end
		else if((count>20'd389 && botton2_counter==5'd9)||(count<20'd364 && botton2_counter==5'd9))begin
			state<=4'd0;
			cs_n<=1;
			count<=20'd364;
			out0<=0;
			out1<=0;
			out2<=0;
			out3<=0;
			clk_count<=0;end
		else if((count>20'd414 && botton2_counter==5'd10)||(count<20'd390 && botton2_counter==5'd10))begin
			state<=4'd0;
			cs_n<=1;
			count<=20'd390;
			out0<=0;
			out1<=0;
			out2<=0;
			out3<=0;
			clk_count<=0;end
		
			
		else begin
		  
			case (count)
				20'd0:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000001;end   //commemd        AVTIVE
				20'd1:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000000;end   //commemd        AVTIVE
				20'd2:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000000;end   //commemd        AVTIVE
				
				20'd3:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000614500;end   //SPI commemd        CLKEXT 
				20'd4:begin int<=280'h000000000000000000000000000000000000000000000000000000302008DEDEDEDEDE;end   //SPI 64bit
				20'd5:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0200C00870004;end   //SPI 56bit				REG_FREQUENCY
				20'd6:begin int<=280'h000000000000000000000000000000000000000000000000000000000000B0202CA003;end   //SPI 40bit				REG_HCYCLE 
				20'd7:begin int<=280'h000000000000000000000000000000000000000000000000000000000000B020305800;end   //SPI 40bit				REG_HOFFSET 
				20'd8:begin int<=280'h000000000000000000000000000000000000000000000000000000000000B020380000;end   //SPI 40bit				REG_HSYNC0
				20'd9:begin int<=280'h000000000000000000000000000000000000000000000000000000000000B0203C3000;end   //SPI 40bit				REG_HSYNC1
				20'd10:begin int<=280'h000000000000000000000000000000000000000000000000000000000000B020400D02;end  //SPI 40bit				REG_VCYCLE
				20'd11:begin int<=280'h000000000000000000000000000000000000000000000000000000000000B020442000;end  //SPI 40bit				REG_VOFFSET			
				20'd12:begin int<=280'h000000000000000000000000000000000000000000000000000000000000B0204C0000;end  //SPI 40bit				REG_VSYNCO
				20'd13:begin int<=280'h000000000000000000000000000000000000000000000000000000000000B020500300;end  //SPI 40bit				REG_VSYNC1			
				20'd14:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0206400;end  //SPI 32bit				REG_SWIZZLF
				20'd15:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0206C01;end  //SPI 32bit				REG_PCLK_POL
				20'd16:begin int<=280'h000000000000000000000000000000000000000000000000000000000000B020342003;end  //SPI 40bit				REG_HSIZE
				20'd17:begin int<=280'h000000000000000000000000000000000000000000000000000000000000B02048E001;end  //SPI 40bit				REG_VSIZE
				20'd18:begin int<=280'h000000000000000000000000000000000000000000000000000000000000B020680000;end  //SPI 40bit				REG_CSPREAD
				20'd19:begin int<=280'h000000000000000000000000000000000000000000000000000000000000B020600100;end  //SPI 40bit				REG_DITHER
				20'd20:begin int<=280'h000000000000000000000000000000000000000000000000000000000000B021180807;end  //SPI 40bit				REG_TOUCH_RZTHRESH
				20'd21:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B02090FF;end  //SPI 32bit				REG_GPIO_DIR
				20'd22:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B02094FF;end  //SPI 32bit				REG_GPIO		
			
				20'd23:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0000007000026;end  //SPI 56bit  	CLEAR 
				20'd24:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000040100001F;end  //SPI 56bit  	BEGIN BITMAPS
				20'd25:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00008335BD99C;end  //SPI 56bit  	30k_3	
				20'd26:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0000C305B199E;end  //SPI 56bit  	30k_0
				20'd27:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000106B5B599F;end  //SPI 56bit  	30k_K
				20'd28:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00014335B19A3;end  //SPI 56bit  	31k_3
				20'd29:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00018315B59A4;end  //SPI 56bit  	31k_1
				20'd30:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0001C6B5B99A5;end  //SPI 56bit  	31k_K				
				20'd31:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00020335B59A9;end  //SPI 56bit  	32k_3				
				20'd32:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00024325B99AA;end  //SPI 56bit  	32k_2			
				20'd33:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000286B5BD9AB;end  //SPI 56bit  	32k_K			
				20'd34:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0002C335B99AF;end  //SPI 56bit  	33k_3			
				20'd35:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00030335BD9B0;end  //SPI 56bit  	33k_3			
				20'd36:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000346B5B19B2;end  //SPI 56bit  	33k_K			
				20'd37:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00038335BD9B5;end  //SPI 56bit  	34k_3			
				20'd38:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0003C345B19B7;end  //SPI 56bit  	34k_4			
				20'd39:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000406B5B59B8;end  //SPI 56bit  	34k_K			
				20'd40:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00044335B19BC;end  //SPI 56bit  	35k_3			
				20'd41:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00048355B59BD;end  //SPI 56bit  	35k_5			
				20'd42:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0004C6B5B99BE;end  //SPI 56bit  	35k_K
				20'd43:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0005000000021;end  //SPI 56bit  	BITMAPS END
			
				20'd44:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000540100001F;end  //SPI 56bit  	BEGIN BITMAPS
				20'd45:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000582021002B;end  //SPI 56bit  	VERTEX_TRANSLATE_X
				20'd46:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0005C335B1980;end  //SPI 56bit  	36k_3
				20'd47:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00060365B5981;end  //SPI 56bit  	36k_6
				20'd48:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000646B5B9982;end  //SPI 56bit  	36k_K
				20'd49:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00068335B5986;end  //SPI 56bit  	37k_3
				20'd50:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0006C375B9987;end  //SPI 56bit  	37k_7
				20'd51:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000706B5BD988;end  //SPI 56bit  	37k_K
				20'd52:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00074335B998C;end  //SPI 56bit  	38k_3
				20'd53:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00078385BD98D;end  //SPI 56bit  	38k_8				
				20'd54:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0007C6B5B198F;end  //SPI 56bit  	38k_K				
				20'd55:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00080335BD992;end  //SPI 56bit  	39k_3				
				20'd56:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00084395B1994;end  //SPI 56bit  	39k_9				
				20'd57:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000886B5B5995;end  //SPI 56bit  	39k_K				
				20'd58:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0008C345B1999;end  //SPI 56bit  	40k_4				
				20'd59:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00090305B599A;end  //SPI 56bit  	40k_0				
				20'd60:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000946B5B999B;end  //SPI 56bit  	40k_K	
				20'd61:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0009800000021;end  //SPI 56bit  	BITMAPS END
				
				20'd62:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0009C0000002B;end  //SPI 56bit  	VERTEX_TRANSLATE_X
				
				20'd63:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000A00300001F;end  //SPI 56bit		BEGIN LINES
				20'd64:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000A4FFFFFF04;end  //SPI 56bit		LINES COLER
				20'd65:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000A81E00000E;end  //SPI 56bit		LINES WIDTH
				20'd66:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000AC00001999;end  //SPI 56bit		LINES_X LOCATION_1
				20'd67:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000B000197057;end  //SPI 56bit		LINES_X LOCATION_2
		
				20'd68:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000B400001999;end  //SPI 56bit		LINES_Y LOCATION_1
				20'd69:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000B800E00199;end  //SPI 56bit		LINES_Y LOCATION_2
				
				
				20'd70:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000BC00000021;end  //SPI 56bit		LINES END
		
				20'd71:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000C00900001F;end  //SPI 56bit		BEGIN RECTS
				20'd72:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000C464646404;end  //SPI 56bit		RECTS COLER 
				20'd73:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000C85000000E;end  //SPI 56bit		RECTS WIDTH
				20'd74:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000CC0000C283;end  //SPI 56bit		RECTS1 LOCATION_1
				20'd75:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000D000004790;end  //SPI 56bit		RECTS1 LOCATION_2
			
				20'd76:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000D464646404;end  //SPI 56bit		RECTS2 COLER 
				20'd77:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000D85000000E;end  //SPI 56bit		RECTS2 WIDTH
				20'd78:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000DC0009F040;end  //SPI 56bit		RECTS2 LOCATION_1
				20'd79:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000E0000E1044;end  //SPI 56bit		RECTS2 LOCATION_2
				
				20'd80:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000E464646404;end  //SPI 56bit		RECTS3 COLER 
				20'd81:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000E85000000E;end  //SPI 56bit		RECTS3 WIDTH
				20'd82:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000EC0000D083;end  //SPI 56bit		RECTS3 LOCATION_1
				20'd83:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000F000005590;end  //SPI 56bit		RECTS3 LOCATION_2
			
				20'd84:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000F464646404;end  //SPI 56bit		RECTS4 COLER 
				20'd85:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000F85000000E;end  //SPI 56bit		RECTS4 WIDTH
				20'd86:begin int<=280'h00000000000000000000000000000000000000000000000000000000B000FC0000D783;end  //SPI 56bit		RECTS4 LOCATION_1
				20'd87:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0010000005C90;end  //SPI 56bit		RECTS4 LOCATION_2
			
				20'd88:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0010400000021;end  //SPI 56bit		RECTS END
			
				
				
				20'd89:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001080100001F;end  //SPI 56bit  	BEGIN BITMAPS
				20'd90:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0010CFFFFFF04;end  //SPI 56bit		BITMAPS COLER 
				
				20'd91:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00110418B9696;end  //SPI 56bit  	4.0A_A	
				20'd92:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00114308B5695;end  //SPI 56bit  	4.0A_0
				20'd93:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001182E8BB694;end  //SPI 56bit  	4.0A_.
				20'd94:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0011C348B7693;end  //SPI 56bit  	4.0A_4
		
				20'd95:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00120410B9496;end  //SPI 56bit  	4.5A_A
				20'd96:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00124350B5495;end  //SPI 56bit  	4.5A_5
				20'd97:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001282E0BB494;end  //SPI 56bit  	4.5A_.
				20'd98:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0012C340B7493;end  //SPI 56bit  	4.5A_4
		
				20'd99:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00130418B9196;end  //SPI 56bit  	5.0A_A
				20'd100:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00134308B5195;end  //SPI 56bit  	5.0A_0
				20'd101:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001382E8BB194;end  //SPI 56bit  	5.0A_.
				20'd102:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0013C358B7193;end  //SPI 56bit  	5.0A_5
			
				20'd103:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00140410B8F96;end  //SPI 56bit  	5.5A_A
				20'd104:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00144350B4F95;end  //SPI 56bit  	5.5A_5
				20'd105:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001482E0BAF94;end  //SPI 56bit  	5.5A_.
				20'd106:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0014C350B6F93;end  //SPI 56bit  	5.5A_5

				20'd107:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00150418B8C96;end  //SPI 56bit  	6.0A_A				
				20'd108:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00154308B4C95;end  //SPI 56bit  	6.0A_0				
				20'd109:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001582E8BAC94;end  //SPI 56bit  	6.0A_.	
				20'd110:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0015C368B6C93;end  //SPI 56bit  	6.0A_6
				
				20'd111:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00160410B8A96;end  //SPI 56bit  	6.5A_A				
				20'd112:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00164350B4A95;end  //SPI 56bit  	6.5A_5				
				20'd113:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001682E0BAA94;end  //SPI 56bit  	6.5A_.				
				20'd114:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0016C360B6A93;end  //SPI 56bit  	6.5A_6
			
				20'd115:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00170418B8796;end  //SPI 56bit  	7.0A_A				
				20'd116:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00174308B4795;end  //SPI 56bit  	7.0A_0		
				20'd117:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001782E8BA794;end  //SPI 56bit  	7.0A_.
				20'd118:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0017C378B6793;end  //SPI 56bit  	7.0A_7
			
				20'd119:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00180410B8596;end  //SPI 56bit  	7.5A_A
				20'd120:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00184350B4595;end  //SPI 56bit  	7.5A_5			
				20'd121:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001882E0BA594;end  //SPI 56bit  	7.5A_.		
				20'd122:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0018C370B6593;end  //SPI 56bit  	7.5A_7
			
				20'd123:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00190418B8296;end  //SPI 56bit  	8.0A_A			
				20'd124:begin int<=280'h00000000000000000000000000000000000000000000000000000000B00194308B4295;end  //SPI 56bit  	8.0A_0			
				20'd125:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001982E8BA294;end  //SPI 56bit  	8.0A_.			
				20'd126:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0019C388B6293;end  //SPI 56bit  	8.0A_8
				
				20'd127:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001A04F9CEA86;end  //SPI 56bit  	OFF_O
				20'd128:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001A4469C6A89;end  //SPI 56bit  	OFF_F
				20'd129:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001A8469CEA8B;end  //SPI 56bit  	OFF_F
				
				20'd130:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001AC529CE386;end  //SPI 56bit  	OPEN_R
				20'd131:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001B0559C6389;end  //SPI 56bit  	OPEN_U
				20'd132:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001B44E9CE38B;end  //SPI 56bit  	OPEN_N
				20'd133:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001B84E9C838C;end  //SPI 56bit  	OPEN_N
			
				20'd134:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001BC4C9C1885;end  //SPI 56bit  	LOCK_L
				20'd135:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001C04F9C9887;end  //SPI 56bit  	LOCK_O
				20'd136:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001C4439C188A;end  //SPI 56bit  	LOCK_C
				20'd137:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001C84B9C988C;end  //SPI 56bit  	LOCK_K
				
				20'd138:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001CC539CB185;end  //SPI 56bit  	SWEEP_S
				20'd139:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001D0579C9187;end  //SPI 56bit  	SWEEP_W
				20'd140:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001D4459C118A;end  //SPI 56bit  	SWEEP_E
				20'd141:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001D8459CF18B;end  //SPI 56bit  	SWEEP_E
				20'd142:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001DC509CD18D;end  //SPI 56bit  	SWEEP_P

				20'd143:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001E000000021;end  //SPI 56bit  	BITMAPS END
				
				
				20'd144:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001E40400001F;end  //SPI 56bit	BEGIN LINE_STRIP
				20'd145:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001E800FFFF04;end  //SPI 56bit	LINES COLER
				20'd146:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001EC3000000E;end  //SPI 56bit	LINES WIDTH
			
//				20'd147:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001F00000149E;end  //SPI 56bit	LINES LOCATION_1
				20'd147:begin int<={248'h00000000000000000000000000000000000000000000000000000000B001F0,true_map_current[0],16'h8047};end  //SPI 56bit	LINES LOCATION_1
				
				
				20'd148:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001F400000021;end  //SPI 56bit	LINES END
				20'd149:begin int<=280'h00000000000000000000000000000000000000000000000000000000B001F800000000;end  //SPI 56bit	DISPLAY	
				
				20'd150:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0205402;end  //SPI 32bit 	io2,io3=1		REG_DLSWAP 
				20'd151:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0207002;end  //SPI 32bit 	io2,io3=1		REG_PCLK
				20'd152:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000000;end  //commemd        AVTIVE
				20'd153:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end 
				20'd154:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd155:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd156:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd157:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd158:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				
			/////////////////////////////////////////////////////////LINES LOCATION_2/////////////////////////////////////////////////////////////////////////////			
								
				20'd159:begin int<=280'hB00000070000260100001F335BD99C305B199E6B5B599F335B19A3315B59A46B5B99A5;end  //SPI 280bit		
				20'd160:begin int<=280'hB00020335B59A9325B99AA6B5BD9AB335B99AF335BD9B06B5B19B2335BD9B5345B19B7;end  //SPI 280bit		
				20'd161:begin int<=280'hB000406B5B59B8335B19BC355B59BD6B5B99BE000000210100001F2021002B335B1980;end  //SPI 280bit		
				20'd162:begin int<=280'hB00060365B59816B5B9982335B5986375B99876B5BD988335B998C385BD98D6B5B198F;end  //SPI 280bit		
				20'd163:begin int<=280'hB00080335BD992395B19946B5B5995345B1999305B599A6B5B999B000000210000002B;end  //SPI 280bit		
				20'd164:begin int<=280'hB000A00300001FFFFFFF041E00000E00001999001970570000199900E0019900000021;end  //SPI 280bit		
				20'd165:begin int<=280'hB000C00900001F646464045000000E0000C28300004790646464045000000E0009F040;end  //SPI 280bit		
				20'd166:begin int<=280'hB000E0000E1044646464045000000E0000D08300005590646464045000000E0000D783;end  //SPI 280bit		
				20'd167:begin int<=280'hB0010000005C90000000210100001FFFFFFF04418B9696308B56952E8BB694348B7693;end  //SPI 280bit		
				20'd168:begin int<=280'hB00120410B9496350B54952E0BB494340B7493418B9196308B51952E8BB194358B7193;end  //SPI 280bit		
				20'd169:begin int<=280'hB00140410B8F96350B4F952E0BAF94350B6F93418B8C96308B4C952E8BAC94368B6C93;end  //SPI 280bit		
				20'd170:begin int<=280'hB00160410B8A96350B4A952E0BAA94360B6A93418B8796308B47952E8BA794378B6793;end  //SPI 280bit		
				20'd171:begin int<=280'hB00180410B8596350B45952E0BA594370B6593418B8296308B42952E8BA294388B6293;end  //SPI 280bit		
				20'd172:begin int<=280'hB001A04F9CEA86469C6A89469CEA8B529CE386559C63894E9CE38B4C9C18854F9C9887;end  //SPI 280bit		
				20'd173:begin int<=280'hB001C0439C188A4B9C988C539CB185579C9187459C118A459CF18B509CD18D00000021;end  //SPI 280bit		
//				20'd174:begin int<=280'h00000000B001E00400001F00FFFF043000000E0000149E00004AA40000002100000000;end  //SPI 248bit		
				20'd174:begin int<={152'h00000000B001E00400001F00FFFF043000000E,true_map_current[0],16'h8047,true_map_current[1],16'h1049,64'h0000002100000000};end  //SPI 248bit	
				
				
				20'd175:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0205402;end  //SPI 32bit 	io2,io3=1		REG_DLSWAP 
				20'd176:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0207002;end  //SPI 32bit 	io2,io3=1		REG_PCLK
				20'd177:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000000;end  //commemd        AVTIVE
				20'd178:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end 
				20'd179:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd180:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd181:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd182:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd183:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end

				
		/////////////////////////////////////////////////////////LINES LOCATION_3/////////////////////////////////////////////////////////////////////////////			
				
				20'd184:begin int<=280'hB00000070000260100001F335BD99C305B199E6B5B599F335B19A3315B59A46B5B99A5;end  //SPI 280bit		
				20'd185:begin int<=280'hB00020335B59A9325B99AA6B5BD9AB335B99AF335BD9B06B5B19B2335BD9B5345B19B7;end  //SPI 280bit		
				20'd186:begin int<=280'hB000406B5B59B8335B19BC355B59BD6B5B99BE000000210100001F2021002B335B1980;end  //SPI 280bit		
				20'd187:begin int<=280'hB00060365B59816B5B9982335B5986375B99876B5BD988335B998C385BD98D6B5B198F;end  //SPI 280bit		
				20'd188:begin int<=280'hB00080335BD992395B19946B5B5995345B1999305B599A6B5B999B000000210000002B;end  //SPI 280bit		
				20'd189:begin int<=280'hB000A00300001FFFFFFF041E00000E00001999001970570000199900E0019900000021;end  //SPI 280bit		
				20'd190:begin int<=280'hB000C00900001F646464045000000E0000C28300004790646464045000000E0009F040;end  //SPI 280bit		
				20'd191:begin int<=280'hB000E0000E1044646464045000000E0000D08300005590646464045000000E0000D783;end  //SPI 280bit		
				20'd192:begin int<=280'hB0010000005C90000000210100001FFFFFFF04418B9696308B56952E8BB694348B7693;end  //SPI 280bit		
				20'd193:begin int<=280'hB00120410B9496350B54952E0BB494340B7493418B9196308B51952E8BB194358B7193;end  //SPI 280bit		
				20'd194:begin int<=280'hB00140410B8F96350B4F952E0BAF94350B6F93418B8C96308B4C952E8BAC94368B6C93;end  //SPI 280bit		
				20'd195:begin int<=280'hB00160410B8A96350B4A952E0BAA94360B6A93418B8796308B47952E8BA794378B6793;end  //SPI 280bit		
				20'd196:begin int<=280'hB00180410B8596350B45952E0BA594370B6593418B8296308B42952E8BA294388B6293;end  //SPI 280bit		
				20'd197:begin int<=280'hB001A04F9CEA86469C6A89469CEA8B529CE386559C63894E9CE38B4C9C18854F9C9887;end  //SPI 280bit		
				20'd198:begin int<=280'hB001C0439C188A4B9C988C539CB185579C9187459C118A459CF18B509CD18D00000021;end  //SPI 280bit		
//				20'd199:begin int<=280'hB001E00400001F00FFFF043000000E0000149E00004AA400808CAA0000002100000000;end  //SPI 280bit
				20'd199:begin int<={120'hB001E00400001F00FFFF043000000E,true_map_current[0],16'h8047,true_map_current[1],16'h1049,true_map_current[2],16'hA04A,64'h0000002100000000};end  //SPI 280bit
		
			
				20'd200:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0205402;end  //SPI 32bit 	io2,io3=1		REG_DLSWAP 
				20'd201:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0207002;end  //SPI 32bit 	io2,io3=1		REG_PCLK
				20'd202:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000000;end  //commemd        AVTIVE
				20'd203:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end 
				20'd204:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd205:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd206:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd207:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd208:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end

			
		/////////////////////////////////////////////////////////LINES LOCATION_4/////////////////////////////////////////////////////////////////////////////			
				
				20'd209:begin int<=280'hB00000070000260100001F335BD99C305B199E6B5B599F335B19A3315B59A46B5B99A5;end  //SPI 280bit		
				20'd210:begin int<=280'hB00020335B59A9325B99AA6B5BD9AB335B99AF335BD9B06B5B19B2335BD9B5345B19B7;end  //SPI 280bit		
				20'd211:begin int<=280'hB000406B5B59B8335B19BC355B59BD6B5B99BE000000210100001F2021002B335B1980;end  //SPI 280bit		
				20'd212:begin int<=280'hB00060365B59816B5B9982335B5986375B99876B5BD988335B998C385BD98D6B5B198F;end  //SPI 280bit		
				20'd213:begin int<=280'hB00080335BD992395B19946B5B5995345B1999305B599A6B5B999B000000210000002B;end  //SPI 280bit		
				20'd214:begin int<=280'hB000A00300001FFFFFFF041E00000E00001999001970570000199900E0019900000021;end  //SPI 280bit		
				20'd215:begin int<=280'hB000C00900001F646464045000000E0000C28300004790646464045000000E0009F040;end  //SPI 280bit		
				20'd216:begin int<=280'hB000E0000E1044646464045000000E0000D08300005590646464045000000E0000D783;end  //SPI 280bit		
				20'd217:begin int<=280'hB0010000005C90000000210100001FFFFFFF04418B9696308B56952E8BB694348B7693;end  //SPI 280bit		
				20'd218:begin int<=280'hB00120410B9496350B54952E0BB494340B7493418B9196308B51952E8BB194358B7193;end  //SPI 280bit		
				20'd219:begin int<=280'hB00140410B8F96350B4F952E0BAF94350B6F93418B8C96308B4C952E8BAC94368B6C93;end  //SPI 280bit		
				20'd220:begin int<=280'hB00160410B8A96350B4A952E0BAA94360B6A93418B8796308B47952E8BA794378B6793;end  //SPI 280bit		
				20'd221:begin int<=280'hB00180410B8596350B45952E0BA594370B6593418B8296308B42952E8BA294388B6293;end  //SPI 280bit		
				20'd222:begin int<=280'hB001A04F9CEA86469C6A89469CEA8B529CE386559C63894E9CE38B4C9C18854F9C9887;end  //SPI 280bit		
				20'd223:begin int<=280'hB001C0439C188A4B9C988C539CB185579C9187459C118A459CF18B509CD18D00000021;end  //SPI 280bit		
//				20'd224:begin int<=280'hB001E00400001F00FFFF043000000E0000149E00004AA400808CAA0040CBB000000021;end  //SPI 280bit
				20'd224:begin int<={120'hB001E00400001F00FFFF043000000E,true_map_current[0],16'h8047,true_map_current[1],16'h1049,true_map_current[2],16'hA04A,true_map_current[3],16'h304C,32'h00000021};end  //SPI 280bit
				20'd225:begin int<=280'h00000000000000000000000000000000000000000000000000000000B0020000000000;end  //SPI 56bit		
		
				20'd226:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0205402;end  //SPI 32bit 	io2,io3=1		REG_DLSWAP 
				20'd227:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0207002;end  //SPI 32bit 	io2,io3=1		REG_PCLK
				20'd228:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000000;end  //commemd        AVTIVE
				20'd229:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end 
				20'd230:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd231:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd232:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd233:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd234:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end

					
		/////////////////////////////////////////////////////////LINES LOCATION_5/////////////////////////////////////////////////////////////////////////////			
				
				20'd235:begin int<=280'hB00000070000260100001F335BD99C305B199E6B5B599F335B19A3315B59A46B5B99A5;end  //SPI 280bit		
				20'd236:begin int<=280'hB00020335B59A9325B99AA6B5BD9AB335B99AF335BD9B06B5B19B2335BD9B5345B19B7;end  //SPI 280bit		
				20'd237:begin int<=280'hB000406B5B59B8335B19BC355B59BD6B5B99BE000000210100001F2021002B335B1980;end  //SPI 280bit		
				20'd238:begin int<=280'hB00060365B59816B5B9982335B5986375B99876B5BD988335B998C385BD98D6B5B198F;end  //SPI 280bit		
				20'd239:begin int<=280'hB00080335BD992395B19946B5B5995345B1999305B599A6B5B999B000000210000002B;end  //SPI 280bit		
				20'd240:begin int<=280'hB000A00300001FFFFFFF041E00000E00001999001970570000199900E0019900000021;end  //SPI 280bit		
				20'd241:begin int<=280'hB000C00900001F646464045000000E0000C28300004790646464045000000E0009F040;end  //SPI 280bit		
				20'd242:begin int<=280'hB000E0000E1044646464045000000E0000D08300005590646464045000000E0000D783;end  //SPI 280bit		
				20'd243:begin int<=280'hB0010000005C90000000210100001FFFFFFF04418B9696308B56952E8BB694348B7693;end  //SPI 280bit		
				20'd244:begin int<=280'hB00120410B9496350B54952E0BB494340B7493418B9196308B51952E8BB194358B7193;end  //SPI 280bit		
				20'd245:begin int<=280'hB00140410B8F96350B4F952E0BAF94350B6F93418B8C96308B4C952E8BAC94368B6C93;end  //SPI 280bit		
				20'd246:begin int<=280'hB00160410B8A96350B4A952E0BAA94360B6A93418B8796308B47952E8BA794378B6793;end  //SPI 280bit		
				20'd247:begin int<=280'hB00180410B8596350B45952E0BA594370B6593418B8296308B42952E8BA294388B6293;end  //SPI 280bit		
				20'd248:begin int<=280'hB001A04F9CEA86469C6A89469CEA8B529CE386559C63894E9CE38B4C9C18854F9C9887;end  //SPI 280bit		
				20'd249:begin int<=280'hB001C0439C188A4B9C988C539CB185579C9187459C118A459CF18B509CD18D00000021;end  //SPI 280bit		
//				20'd250:begin int<=280'hB001E00400001F00FFFF043000000E0000149E00004AA400808CAA0040CBB0008011B7;end  //SPI 280bit
				20'd250:begin int<={120'hB001E00400001F00FFFF043000000E,true_map_current[0],16'h8047,true_map_current[1],16'h1049,true_map_current[2],16'hA04A,true_map_current[3],16'h304C,,true_map_current[4],16'hC04D};end  //SPI 280bit
				20'd251:begin int<=280'h000000000000000000000000000000000000000000000000B002000000002100000000;end  //SPI 88bit		
	
				20'd252:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0205402;end  //SPI 32bit 	io2,io3=1		REG_DLSWAP 
				20'd253:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0207002;end  //SPI 32bit 	io2,io3=1		REG_PCLK
				20'd254:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000000;end  //commemd        AVTIVE
				20'd255:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end 
				20'd256:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd257:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd258:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd259:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
	
			
		/////////////////////////////////////////////////////////LINES LOCATION_6/////////////////////////////////////////////////////////////////////////////			
				
				20'd260:begin int<=280'hB00000070000260100001F335BD99C305B199E6B5B599F335B19A3315B59A46B5B99A5;end  //SPI 280bit		
				20'd261:begin int<=280'hB00020335B59A9325B99AA6B5BD9AB335B99AF335BD9B06B5B19B2335BD9B5345B19B7;end  //SPI 280bit		
				20'd262:begin int<=280'hB000406B5B59B8335B19BC355B59BD6B5B99BE000000210100001F2021002B335B1980;end  //SPI 280bit		
				20'd263:begin int<=280'hB00060365B59816B5B9982335B5986375B99876B5BD988335B998C385BD98D6B5B198F;end  //SPI 280bit		
				20'd264:begin int<=280'hB00080335BD992395B19946B5B5995345B1999305B599A6B5B999B000000210000002B;end  //SPI 280bit		
				20'd265:begin int<=280'hB000A00300001FFFFFFF041E00000E00001999001970570000199900E0019900000021;end  //SPI 280bit		
				20'd266:begin int<=280'hB000C00900001F646464045000000E0000C28300004790646464045000000E0009F040;end  //SPI 280bit		
				20'd267:begin int<=280'hB000E0000E1044646464045000000E0000D08300005590646464045000000E0000D783;end  //SPI 280bit		
				20'd268:begin int<=280'hB0010000005C90000000210100001FFFFFFF04418B9696308B56952E8BB694348B7693;end  //SPI 280bit		
				20'd269:begin int<=280'hB00120410B9496350B54952E0BB494340B7493418B9196308B51952E8BB194358B7193;end  //SPI 280bit		
				20'd270:begin int<=280'hB00140410B8F96350B4F952E0BAF94350B6F93418B8C96308B4C952E8BAC94368B6C93;end  //SPI 280bit		
				20'd271:begin int<=280'hB00160410B8A96350B4A952E0BAA94360B6A93418B8796308B47952E8BA794378B6793;end  //SPI 280bit		
				20'd272:begin int<=280'hB00180410B8596350B45952E0BA594370B6593418B8296308B42952E8BA294388B6293;end  //SPI 280bit		
				20'd273:begin int<=280'hB001A04F9CEA86469C6A89469CEA8B529CE386559C63894E9CE38B4C9C18854F9C9887;end  //SPI 280bit		
				20'd274:begin int<=280'hB001C0439C188A4B9C988C539CB185579C9187459C118A459CF18B509CD18D00000021;end  //SPI 280bit		
//				20'd275:begin int<=280'hB001E00400001F00FFFF043000000E0000149E00004AA400808CAA0040CBB0008011B7;end  //SPI 280bit
				20'd275:begin int<={120'hB001E00400001F00FFFF043000000E,true_map_current[0],16'h8047,true_map_current[1],16'h1049,true_map_current[2],16'hA04A,true_map_current[3],16'h304C,,true_map_current[4],16'hC04D};end  //SPI 280bit
//				20'd276:begin int<=280'h0000000000000000000000000000000000000000B00200008056BD0000002100000000;end  //SPI 120bit		
				20'd276:begin int<={184'h0000000000000000000000000000000000000000B00200,true_map_current[5],16'h504F,64'h0000002100000000};end  //SPI 120bit
				
				
				20'd277:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0205402;end  //SPI 32bit 	io2,io3=1		REG_DLSWAP 
				20'd278:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0207002;end  //SPI 32bit 	io2,io3=1		REG_PCLK
				20'd279:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000000;end  //commemd        AVTIVE
				20'd280:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end 
				20'd281:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd282:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd283:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd284:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd285:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				
				
	



		
		/////////////////////////////////////////////////////////LINES LOCATION_7/////////////////////////////////////////////////////////////////////////////			
				
				20'd286:begin int<=280'hB00000070000260100001F335BD99C305B199E6B5B599F335B19A3315B59A46B5B99A5;end  //SPI 280bit		
				20'd287:begin int<=280'hB00020335B59A9325B99AA6B5BD9AB335B99AF335BD9B06B5B19B2335BD9B5345B19B7;end  //SPI 280bit		
				20'd288:begin int<=280'hB000406B5B59B8335B19BC355B59BD6B5B99BE000000210100001F2021002B335B1980;end  //SPI 280bit		
				20'd289:begin int<=280'hB00060365B59816B5B9982335B5986375B99876B5BD988335B998C385BD98D6B5B198F;end  //SPI 280bit		
				20'd290:begin int<=280'hB00080335BD992395B19946B5B5995345B1999305B599A6B5B999B000000210000002B;end  //SPI 280bit		
				20'd291:begin int<=280'hB000A00300001FFFFFFF041E00000E00001999001970570000199900E0019900000021;end  //SPI 280bit		
				20'd292:begin int<=280'hB000C00900001F646464045000000E0000C28300004790646464045000000E0009F040;end  //SPI 280bit		
				20'd293:begin int<=280'hB000E0000E1044646464045000000E0000D08300005590646464045000000E0000D783;end  //SPI 280bit		
				20'd294:begin int<=280'hB0010000005C90000000210100001FFFFFFF04418B9696308B56952E8BB694348B7693;end  //SPI 280bit		
				20'd295:begin int<=280'hB00120410B9496350B54952E0BB494340B7493418B9196308B51952E8BB194358B7193;end  //SPI 280bit		
				20'd296:begin int<=280'hB00140410B8F96350B4F952E0BAF94350B6F93418B8C96308B4C952E8BAC94368B6C93;end  //SPI 280bit		
				20'd297:begin int<=280'hB00160410B8A96350B4A952E0BAA94360B6A93418B8796308B47952E8BA794378B6793;end  //SPI 280bit		
				20'd298:begin int<=280'hB00180410B8596350B45952E0BA594370B6593418B8296308B42952E8BA294388B6293;end  //SPI 280bit		
				20'd299:begin int<=280'hB001A04F9CEA86469C6A89469CEA8B529CE386559C63894E9CE38B4C9C18854F9C9887;end  //SPI 280bit		
				20'd300:begin int<=280'hB001C0439C188A4B9C988C539CB185579C9187459C118A459CF18B509CD18D00000021;end  //SPI 280bit		
//				20'd301:begin int<=280'hB001E00400001F00FFFF043000000E0000149E00004AA400808CAA0040CBB0008011B7;end  //SPI 280bit
				20'd301:begin int<={120'hB001E00400001F00FFFF043000000E,true_map_current[0],16'h8047,true_map_current[1],16'h1049,true_map_current[2],16'hA04A,true_map_current[3],16'h304C,,true_map_current[4],16'hC04D};end  //SPI 280bit
//				20'd302:begin int<=280'h00000000000000000000000000000000B00200008056BDA014E0500000002100000000;end  //SPI 152bit
				20'd302:begin int<={152'h00000000000000000000000000000000B00200,true_map_current[5],16'h504F,true_map_current[6],16'hE050,64'h0000002100000000};end  //SPI 152bit		
		
				20'd303:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0205402;end  //SPI 32bit 	io2,io3=1		REG_DLSWAP 
				20'd304:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0207002;end  //SPI 32bit 	io2,io3=1		REG_PCLK
				20'd305:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000000;end  //commemd        AVTIVE
				20'd306:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end 
				20'd307:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd308:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd309:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd310:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd311:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end

			
		/////////////////////////////////////////////////////////LINES LOCATION_8/////////////////////////////////////////////////////////////////////////////			
				
				20'd312:begin int<=280'hB00000070000260100001F335BD99C305B199E6B5B599F335B19A3315B59A46B5B99A5;end  //SPI 280bit		
				20'd313:begin int<=280'hB00020335B59A9325B99AA6B5BD9AB335B99AF335BD9B06B5B19B2335BD9B5345B19B7;end  //SPI 280bit		
				20'd314:begin int<=280'hB000406B5B59B8335B19BC355B59BD6B5B99BE000000210100001F2021002B335B1980;end  //SPI 280bit		
				20'd315:begin int<=280'hB00060365B59816B5B9982335B5986375B99876B5BD988335B998C385BD98D6B5B198F;end  //SPI 280bit		
				20'd316:begin int<=280'hB00080335BD992395B19946B5B5995345B1999305B599A6B5B999B000000210000002B;end  //SPI 280bit		
				20'd317:begin int<=280'hB000A00300001FFFFFFF041E00000E00001999001970570000199900E0019900000021;end  //SPI 280bit		
				20'd318:begin int<=280'hB000C00900001F646464045000000E0000C28300004790646464045000000E0009F040;end  //SPI 280bit		
				20'd319:begin int<=280'hB000E0000E1044646464045000000E0000D08300005590646464045000000E0000D783;end  //SPI 280bit		
				20'd320:begin int<=280'hB0010000005C90000000210100001FFFFFFF04418B9696308B56952E8BB694348B7693;end  //SPI 280bit		
				20'd321:begin int<=280'hB00120410B9496350B54952E0BB494340B7493418B9196308B51952E8BB194358B7193;end  //SPI 280bit		
				20'd322:begin int<=280'hB00140410B8F96350B4F952E0BAF94350B6F93418B8C96308B4C952E8BAC94368B6C93;end  //SPI 280bit		
				20'd323:begin int<=280'hB00160410B8A96350B4A952E0BAA94360B6A93418B8796308B47952E8BA794378B6793;end  //SPI 280bit		
				20'd324:begin int<=280'hB00180410B8596350B45952E0BA594370B6593418B8296308B42952E8BA294388B6293;end  //SPI 280bit		
				20'd325:begin int<=280'hB001A04F9CEA86469C6A89469CEA8B529CE386559C63894E9CE38B4C9C18854F9C9887;end  //SPI 280bit		
				20'd326:begin int<=280'hB001C0439C188A4B9C988C539CB185579C9187459C118A459CF18B509CD18D00000021;end  //SPI 280bit		
//				20'd327:begin int<=280'hB001E00400001F00FFFF043000000E0000149E00004AA400808CAA0040CBB0008011B7;end  //SPI 280bit
//				20'd328:begin int<=280'h000000000000000000000000B00200008056BDA014E050401570520000002100000000;end  //SPI 184bit		
				20'd327:begin int<={120'hB001E00400001F00FFFF043000000E,true_map_current[0],16'h8047,true_map_current[1],16'h1049,true_map_current[2],16'hA04A,true_map_current[3],16'h304C,,true_map_current[4],16'hC04D};end  //SPI 280bit
				20'd328:begin int<={120'h000000000000000000000000B00200,true_map_current[5],16'h504F,true_map_current[6],16'hE050,true_map_current[7],16'h7052,64'h0000002100000000};end  //SPI 184bit
				
				
				
				20'd329:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0205402;end  //SPI 32bit 	io2,io3=1		REG_DLSWAP 
				20'd330:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0207002;end  //SPI 32bit 	io2,io3=1		REG_PCLK
				20'd331:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000000;end  //commemd        AVTIVE
				20'd332:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end 
				20'd333:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd334:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd335:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd336:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd337:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end

				
				
		/////////////////////////////////////////////////////////LINES LOCATION_9/////////////////////////////////////////////////////////////////////////////			
				
				20'd338:begin int<=280'hB00000070000260100001F335BD99C305B199E6B5B599F335B19A3315B59A46B5B99A5;end  //SPI 280bit		
				20'd339:begin int<=280'hB00020335B59A9325B99AA6B5BD9AB335B99AF335BD9B06B5B19B2335BD9B5345B19B7;end  //SPI 280bit		
				20'd340:begin int<=280'hB000406B5B59B8335B19BC355B59BD6B5B99BE000000210100001F2021002B335B1980;end  //SPI 280bit		
				20'd341:begin int<=280'hB00060365B59816B5B9982335B5986375B99876B5BD988335B998C385BD98D6B5B198F;end  //SPI 280bit		
				20'd342:begin int<=280'hB00080335BD992395B19946B5B5995345B1999305B599A6B5B999B000000210000002B;end  //SPI 280bit		
				20'd343:begin int<=280'hB000A00300001FFFFFFF041E00000E00001999001970570000199900E0019900000021;end  //SPI 280bit		
				20'd344:begin int<=280'hB000C00900001F646464045000000E0000C28300004790646464045000000E0009F040;end  //SPI 280bit		
				20'd345:begin int<=280'hB000E0000E1044646464045000000E0000D08300005590646464045000000E0000D783;end  //SPI 280bit		
				20'd346:begin int<=280'hB0010000005C90000000210100001FFFFFFF04418B9696308B56952E8BB694348B7693;end  //SPI 280bit		
				20'd347:begin int<=280'hB00120410B9496350B54952E0BB494340B7493418B9196308B51952E8BB194358B7193;end  //SPI 280bit		
				20'd348:begin int<=280'hB00140410B8F96350B4F952E0BAF94350B6F93418B8C96308B4C952E8BAC94368B6C93;end  //SPI 280bit		
				20'd349:begin int<=280'hB00160410B8A96350B4A952E0BAA94360B6A93418B8796308B47952E8BA794378B6793;end  //SPI 280bit		
				20'd350:begin int<=280'hB00180410B8596350B45952E0BA594370B6593418B8296308B42952E8BA294388B6293;end  //SPI 280bit		
				20'd351:begin int<=280'hB001A04F9CEA86469C6A89469CEA8B529CE386559C63894E9CE38B4C9C18854F9C9887;end  //SPI 280bit		
				20'd352:begin int<=280'hB001C0439C188A4B9C988C539CB185579C9187459C118A459CF18B509CD18D00000021;end  //SPI 280bit		
//				20'd353:begin int<=280'hB001E00400001F00FFFF043000000E0000149E00004AA400808CAA0040CBB0008011B7;end  //SPI 280bit
//				20'd354:begin int<=280'h0000000000000000B00200008056BDA014E05040157052E01500540000002100000000;end  //SPI 216bit
				20'd353:begin int<={120'hB001E00400001F00FFFF043000000E,true_map_current[0],16'h8047,true_map_current[1],16'h1049,true_map_current[2],16'hA04A,true_map_current[3],16'h304C,,true_map_current[4],16'hC04D};end  //SPI 280bit
				20'd354:begin int<={88'h0000000000000000B00200,true_map_current[5],16'h504F,true_map_current[6],16'hE050,true_map_current[7],16'h7052,true_map_current[8],16'h0054,64'h0000002100000000};end  //SPI 216bit
				
	
				20'd355:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0205402;end  //SPI 32bit 	io2,io3=1		REG_DLSWAP 
				20'd356:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0207002;end  //SPI 32bit 	io2,io3=1		REG_PCLK
				20'd357:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000000;end  //commemd        AVTIVE
				20'd358:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end 
				20'd359:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd360:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd361:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd362:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd363:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end

//	
//		/////////////////////////////////////////////////////////LINES LOCATION_10/////////////////////////////////////////////////////////////////////////////			
//				
				20'd364:begin int<=280'hB00000070000260100001F335BD99C305B199E6B5B599F335B19A3315B59A46B5B99A5;end  //SPI 280bit		
				20'd365:begin int<=280'hB00020335B59A9325B99AA6B5BD9AB335B99AF335BD9B06B5B19B2335BD9B5345B19B7;end  //SPI 280bit		
				20'd366:begin int<=280'hB000406B5B59B8335B19BC355B59BD6B5B99BE000000210100001F2021002B335B1980;end  //SPI 280bit		
				20'd367:begin int<=280'hB00060365B59816B5B9982335B5986375B99876B5BD988335B998C385BD98D6B5B198F;end  //SPI 280bit		
				20'd368:begin int<=280'hB00080335BD992395B19946B5B5995345B1999305B599A6B5B999B000000210000002B;end  //SPI 280bit		
				20'd369:begin int<=280'hB000A00300001FFFFFFF041E00000E00001999001970570000199900E0019900000021;end  //SPI 280bit		
				20'd370:begin int<=280'hB000C00900001F646464045000000E0000C28300004790646464045000000E0009F040;end  //SPI 280bit		
				20'd371:begin int<=280'hB000E0000E1044646464045000000E0000D08300005590646464045000000E0000D783;end  //SPI 280bit		
				20'd372:begin int<=280'hB0010000005C90000000210100001FFFFFFF04418B9696308B56952E8BB694348B7693;end  //SPI 280bit		
				20'd373:begin int<=280'hB00120410B9496350B54952E0BB494340B7493418B9196308B51952E8BB194358B7193;end  //SPI 280bit		
				20'd374:begin int<=280'hB00140410B8F96350B4F952E0BAF94350B6F93418B8C96308B4C952E8BAC94368B6C93;end  //SPI 280bit		
				20'd375:begin int<=280'hB00160410B8A96350B4A952E0BAA94360B6A93418B8796308B47952E8BA794378B6793;end  //SPI 280bit		
				20'd376:begin int<=280'hB00180410B8596350B45952E0BA594370B6593418B8296308B42952E8BA294388B6293;end  //SPI 280bit		
				20'd377:begin int<=280'hB001A04F9CEA86469C6A89469CEA8B529CE386559C63894E9CE38B4C9C18854F9C9887;end  //SPI 280bit		
				20'd378:begin int<=280'hB001C0439C188A4B9C988C539CB185579C9187459C118A459CF18B509CD18D00000021;end  //SPI 280bit		
//				20'd379:begin int<=280'hB001E00400001F00FFFF043000000E0000149E00004AA400808CAA0040CBB0008011B7;end  //SPI 280bit
//				20'd380:begin int<=280'h00000000B00200008056BDA014E05040157052E0150054801690550000002100000000;end  //SPI 248bit
				20'd379:begin int<={120'hB001E00400001F00FFFF043000000E,true_map_current[0],16'h8047,true_map_current[1],16'h1049,true_map_current[2],16'hA04A,true_map_current[3],16'h304C,,true_map_current[4],16'hC04D};end  //SPI 280bit
				20'd380:begin int<={56'h00000000B00200,true_map_current[5],16'h504F,true_map_current[6],16'hE050,true_map_current[7],16'h7052,true_map_current[8],16'h0054,true_map_current[9],16'h9055,64'h0000002100000000};end  //SPI 248bit
			
				20'd381:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0205402;end  //SPI 32bit 	io2,io3=1		REG_DLSWAP 
				20'd382:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0207002;end  //SPI 32bit 	io2,io3=1		REG_PCLK
				20'd383:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000000;end  //commemd        AVTIVE
				20'd384:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end 
				20'd385:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd386:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd387:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd388:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd389:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end

				
				
				
		/////////////////////////////////////////////////////////LINES LOCATION_11/////////////////////////////////////////////////////////////////////////////			
				
				20'd390:begin int<=280'hB00000070000260100001F335BD99C305B199E6B5B599F335B19A3315B59A46B5B99A5;end  //SPI 280bit		
				20'd391:begin int<=280'hB00020335B59A9325B99AA6B5BD9AB335B99AF335BD9B06B5B19B2335BD9B5345B19B7;end  //SPI 280bit		
				20'd392:begin int<=280'hB000406B5B59B8335B19BC355B59BD6B5B99BE000000210100001F2021002B335B1980;end  //SPI 280bit		
				20'd393:begin int<=280'hB00060365B59816B5B9982335B5986375B99876B5BD988335B998C385BD98D6B5B198F;end  //SPI 280bit		
				20'd394:begin int<=280'hB00080335BD992395B19946B5B5995345B1999305B599A6B5B999B000000210000002B;end  //SPI 280bit		
				20'd395:begin int<=280'hB000A00300001FFFFFFF041E00000E00001999001970570000199900E0019900000021;end  //SPI 280bit		
				20'd396:begin int<=280'hB000C00900001F646464045000000E0000C28300004790646464045000000E0009F040;end  //SPI 280bit		
				20'd397:begin int<=280'hB000E0000E1044646464045000000E0000D08300005590646464045000000E0000D783;end  //SPI 280bit		
				20'd398:begin int<=280'hB0010000005C90000000210100001FFFFFFF04418B9696308B56952E8BB694348B7693;end  //SPI 280bit		
				20'd399:begin int<=280'hB00120410B9496350B54952E0BB494340B7493418B9196308B51952E8BB194358B7193;end  //SPI 280bit		
				20'd400:begin int<=280'hB00140410B8F96350B4F952E0BAF94350B6F93418B8C96308B4C952E8BAC94368B6C93;end  //SPI 280bit		
				20'd401:begin int<=280'hB00160410B8A96350B4A952E0BAA94360B6A93418B8796308B47952E8BA794378B6793;end  //SPI 280bit		
				20'd402:begin int<=280'hB00180410B8596350B45952E0BA594370B6593418B8296308B42952E8BA294388B6293;end  //SPI 280bit		
				20'd403:begin int<=280'hB001A04F9CEA86469C6A89469CEA8B529CE386559C63894E9CE38B4C9C18854F9C9887;end  //SPI 280bit		
				20'd404:begin int<=280'hB001C0439C188A4B9C988C539CB185579C9187459C118A459CF18B509CD18D00000021;end  //SPI 280bit		
//				20'd405:begin int<=280'hB001E00400001F00FFFF043000000E0000149E00004AA400808CAA0040CBB0008011B7;end  //SPI 280bit
//				20'd406:begin int<={184'hB00200008056BDA014E05040157052E015005480169055,1'h0,true_map_current[10],80'h80560000002100000000};end  //SPI 280bit
//				20'd70:begin int<=280'hB00200008056BDA014E05040157052E015005480169055000F80560000002100000000;end  //SPI 280bit
	//			20'd349:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000B00220;end  //SPI 56bit
				20'd405:begin int<={120'hB001E00400001F00FFFF043000000E,true_map_current[0],16'h8047,true_map_current[1],16'h1049,true_map_current[2],16'hA04A,true_map_current[3],16'h304C,,true_map_current[4],16'hC04D};end  //SPI 280bit
				20'd406:begin int<={24'hB00200,true_map_current[5],16'h504F,true_map_current[6],16'hE050,true_map_current[7],16'h7052,true_map_current[8],16'h0054,true_map_current[9],16'h9055,true_map_current[10],16'h8056,64'h0000002100000000};end  //SPI 280bit

			
				20'd407:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0205402;end  //SPI 32bit 	io2,io3=1		REG_DLSWAP 
				20'd408:begin int<=280'h00000000000000000000000000000000000000000000000000000000000000B0207002;end  //SPI 32bit 	io2,io3=1		REG_PCLK
				20'd409:begin int<=280'h0000000000000000000000000000000000000000000000000000000000000000000000;end  //commemd        AVTIVE
				20'd410:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end 
				20'd411:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd412:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd413:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
				20'd414:begin int<=280'h0000000000000000000000000000000000000000000000000000003021240000000000;end
//				20'd414:begin int<={1'h0,true_map_current[0],1'h0,true_map_current[1],1'h0,true_map_current[2],1'h0,true_map_current[3],1'h0,true_map_current[4],1'h0,true_map_current[5],1'h0,true_map_current[6],1'h0,true_map_current[7],1'h0,true_map_current[8],1'h0,true_map_current[9],1'h0,true_map_current[10],104'd0};end
				default:begin int<=280'd0;end
				endcase
			
			
			
			
			
			
			
			if(position[9]==1)begin
				cs_n<=1;
				cs_ready<=1;
				position<=10'd279;
				position1<=10'd278;
				position2<=10'd277;
				position3<=10'd276;
				count<=count+1;
				clk_count<=0;

			end
			/////////////////////////////////////////////////////SPI commemd 24bit
			else begin
				if(count==20'd0||count==20'd1||count==20'd2||count==20'd3||count==20'd152||count==20'd177||count==20'd202||count==20'd228||count==20'd254||count==20'd279||count==20'd305||count==20'd331||count==20'd357||count==20'd383||count==20'd409)begin
					cs_ready<=0;
					data<=int;
					if(position==10'd279)begin					
						position<=10'd23;
						position1<=10'd22;
						position2<=10'd21;
						position3<=10'd20;end
					else begin
						clk_count<=clk_count+10'd1;
						if(clk_count>=10'd24 && clk_count<=10'd30)begin cs_ready<=1;end
						else begin cs_ready<=0;end
						
						if(cs_ready==0)begin
						cs_n<=0;
						position<=position-10'd1;
						out0<=int[position];
						position1<=position1-10'd1;
						out1<=1'bz;
						position2<=position2-10'd1;
						out2<=0;
						position3<=position3-10'd1;
						out3<=0;end
					end
				end
				/////////////////////////////////////////////////////SPI 32bit
				else if(count==20'd14||count==20'd15||count==20'd21||count==20'd22||count==20'd150||count==20'd151||count==20'd175||count==20'd176||count==20'd200||count==20'd201||count==20'd226||count==20'd227||count==20'd252||count==20'd253||count==20'd277||count==20'd278||count==20'd303||count==20'd304||count==20'd329||count==20'd330||count==20'd355||count==20'd356||count==20'd381||count==20'd382||count==20'd407||count==20'd408)begin
					data<=int;
					cs_ready<=0;
					if(position==10'd279)begin					
						position<=10'd31;
						position1<=10'd30;
						position2<=10'd29;
						position3<=10'd28;
					end
					else begin
						clk_count<=clk_count+10'd1;
						if(clk_count>=10'd24 && clk_count<=10'd30)begin cs_ready<=1;end
						else begin cs_ready<=0;end
					
						if(cs_ready==0)begin
						cs_n<=0;
						position<=position-10'd1;
						out0<=int[position];
						position1<=position1-10'd1;
						out1<=1'bz;
						position2<=position2-10'd1;
						out2<=0;
						position3<=position3-10'd1;
						out3<=0;end
					end
				end
				
					/////////////////////////////////////////////////////SPI 40bit
				else if((count>=20'd6&&count<=20'd13)||(count>=20'd16&&count<=20'd20))begin
					data<=int;
					cs_ready<=0;
					if(position==10'd279)begin					
						position<=10'd39;
						position1<=10'd38;
						position2<=10'd37;
						position3<=10'd36;
					end
					else begin
						clk_count<=clk_count+10'd1;
						if(clk_count>=10'd24 && clk_count<=10'd30)begin cs_ready<=1;end
						else begin cs_ready<=0;end
					
						if(cs_ready==0)begin
						cs_n<=0;
						position<=position-10'd1;
						out0<=int[position];
						position1<=position1-10'd1;
						out1<=1'bz;
						position2<=position2-10'd1;
						out2<=0;
						position3<=position3-10'd1;
						out3<=0;end
					end
				end
				///////////////////////////////////////////////////SPI 64bit
				else if(count==20'd4||(count>=20'd153&&count<=20'd158)||(count>=20'd178&&count<=20'd183)||(count>=20'd229&&count<=20'd234)||(count>=20'd255&&count<=20'd259)||(count>=20'd280&&count<=20'd285)||(count>=20'd306&&count<=20'd311)||(count>=20'd332&&count<=20'd337)||(count>=20'd358&&count<=20'd363)||(count>=20'd384&&count<=20'd389)||(count>=20'd409&&count<=20'd414))begin
					data<=int;
					cs_ready<=0;
					if(position==10'd279)begin					
						position<=10'd63;
						position1<=10'd62;
						position2<=10'd61;
						position3<=10'd60;end
					else begin
						clk_count<=clk_count+10'd1;
						if(clk_count>=10'd24 && clk_count<=10'd30)begin cs_ready<=1;end
						else begin cs_ready<=0;end
					
						if(cs_ready==0)begin
						cs_n<=0;
						position<=position-10'd1;
						out0<=int[position];
						position1<=position1-10'd1;
						out1<=1'bz;
						position1<=position2-10'd1;
						out2<=0;
						position1<=position3-10'd1;
						out3<=0;end
					end
				end
				///////////////////////////////////////////////////SPI 56bit
				else if(count==20'd5||(count>=20'd23&&count<=20'd149)||count==20'd225)begin
					data<=int;
					cs_ready<=0;
					if(position==10'd279)begin					
						position<=10'd55;
						position1<=10'd54;
						position2<=10'd53;
						position3<=10'd52;end
					else begin
						clk_count<=clk_count+10'd1;
						if(clk_count>=10'd24 && clk_count<=10'd30)begin cs_ready<=1;end
						else begin cs_ready<=0;end
					
						if(cs_ready==0)begin
						cs_n<=0;
						position<=position-10'd1;
						out0<=int[position];
						position1<=position1-10'd1;
						out1<=1'bz;
						position1<=position2-10'd1;
						out2<=0;
						position1<=position3-10'd1;
						out3<=0;end
					end
				end
				/////////////////////////////////////////////////////SPI 88bit
				else if(count==20'd251)begin
					data<=int;
					cs_ready<=0;
					if(position==10'd279)begin					
						position<=10'd87;
						position1<=10'd86;
						position2<=10'd85;
						position3<=10'd84;
					end
					else begin
						clk_count<=clk_count+10'd1;
						if(clk_count>=10'd24 && clk_count<=10'd30)begin cs_ready<=1;end
						else begin cs_ready<=0;end
					
						if(cs_ready==0)begin
						cs_n<=0;
						position<=position-10'd1;
						out0<=int[position];
						position1<=position1-10'd1;
						out1<=1'bz;
						position2<=position2-10'd1;
						out2<=0;
						position3<=position3-10'd1;
						out3<=0;end
					end
				end
				/////////////////////////////////////////////////////SPI 120bit
				else if(count==20'd276)begin
					data<=int;
					cs_ready<=0;
					if(position==10'd279)begin					
						position<=10'd119;
						position1<=10'd118;
						position2<=10'd117;
						position3<=10'd116;
					end
					else begin
						clk_count<=clk_count+10'd1;
						if(clk_count>=10'd24 && clk_count<=10'd30)begin cs_ready<=1;end
						else begin cs_ready<=0;end
					
						if(cs_ready==0)begin
						cs_n<=0;
						position<=position-10'd1;
						out0<=int[position];
						position1<=position1-10'd1;
						out1<=1'bz;
						position2<=position2-10'd1;
						out2<=0;
						position3<=position3-10'd1;
						out3<=0;end
					end
				end
				/////////////////////////////////////////////////////SPI 152bit
				else if(count==20'd302)begin
					data<=int;
					cs_ready<=0;
					if(position==10'd279)begin					
						position<=10'd151;
						position1<=10'd150;
						position2<=10'd149;
						position3<=10'd148;
					end
					else begin
						clk_count<=clk_count+10'd1;
						if(clk_count>=10'd24 && clk_count<=10'd30)begin cs_ready<=1;end
						else begin cs_ready<=0;end
					
						if(cs_ready==0)begin
						cs_n<=0;
						position<=position-10'd1;
						out0<=int[position];
						position1<=position1-10'd1;
						out1<=1'bz;
						position2<=position2-10'd1;
						out2<=0;
						position3<=position3-10'd1;
						out3<=0;end
					end
				end
				/////////////////////////////////////////////////////SPI 184bit
				else if(count==20'd328)begin
					data<=int;
					cs_ready<=0;
					if(position==10'd279)begin					
						position<=10'd183;
						position1<=10'd182;
						position2<=10'd181;
						position3<=10'd180;
					end
					else begin
						clk_count<=clk_count+10'd1;
						if(clk_count>=10'd24 && clk_count<=10'd30)begin cs_ready<=1;end
						else begin cs_ready<=0;end
					
						if(cs_ready==0)begin
						cs_n<=0;
						position<=position-10'd1;
						out0<=int[position];
						position1<=position1-10'd1;
						out1<=1'bz;
						position2<=position2-10'd1;
						out2<=0;
						position3<=position3-10'd1;
						out3<=0;end
					end
				end
				/////////////////////////////////////////////////////SPI 216bit
				else if(count==20'd354)begin
					data<=int;
					cs_ready<=0;
					if(position==10'd279)begin					
						position<=10'd215;
						position1<=10'd214;
						position2<=10'd213;
						position3<=10'd212;
					end
					else begin
						clk_count<=clk_count+10'd1;
						if(clk_count>=10'd24 && clk_count<=10'd30)begin cs_ready<=1;end
						else begin cs_ready<=0;end
					
						if(cs_ready==0)begin
						cs_n<=0;
						position<=position-10'd1;
						out0<=int[position];
						position1<=position1-10'd1;
						out1<=1'bz;
						position2<=position2-10'd1;
						out2<=0;
						position3<=position3-10'd1;
						out3<=0;end
					end
				end
				/////////////////////////////////////////////////////SPI 248bit
				else if(count==20'd174||count==20'd380)begin
					data<=int;
					cs_ready<=0;
					if(position==10'd279)begin					
						position<=10'd247;
						position1<=10'd246;
						position2<=10'd245;
						position3<=10'd244;
					end
					else begin
						clk_count<=clk_count+10'd1;
						if(clk_count>=10'd24 && clk_count<=10'd30)begin cs_ready<=1;end
						else begin cs_ready<=0;end
					
						if(cs_ready==0)begin
						cs_n<=0;
						position<=position-10'd1;
						out0<=int[position];
						position1<=position1-10'd1;
						out1<=1'bz;
						position2<=position2-10'd1;
						out2<=0;
						position3<=position3-10'd1;
						out3<=0;end
					end
				end
				///////////////////////////////////////////////////SPI 280bit
				else begin
					data<=int;
					cs_ready<=0;
					
						clk_count<=clk_count+10'd1;
						if(clk_count>=10'd25 && clk_count<=10'd29)begin cs_ready<=1;end
						else begin cs_ready<=0;end
					
						if(cs_ready==0)begin
						cs_n<=0;
						position<=position-10'd1;
						out0<=int[position];
						position1<=position1-10'd1;
						out1<=1'bz;
						position1<=position2-10'd1;
						out2<=0;
						position1<=position3-10'd1;
						out3<=0;end
					
				end
			end	
				
				
		end
	end
//////////////////////////////////////////////////////////////////////////////////// 
			

end


endmodule




