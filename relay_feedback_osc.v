module relay_feedback_osc(alarm,alarm_low,locked_low,test_n,test_p,LED,
					  Gate_Ap,Gate_An,Gate_Bp,Gate_Bn,
					  fault,Vq,Iq,SW,SW2,CS1,CS2,SCLK1,SCLK2,DIN1,DIN2,DOUT1,DOUT2,
					  RS,RW,E,D,clk50MHz,LCD_out0,LCD_out1,LCD_out2,LCD_out3,LCD_csn,LCD_clk,LCD_INT,LCD_PD);
					  
input  SW,Vq,Iq,clk50MHz,DOUT1,DOUT2,SW2;
output CS1,CS2,SCLK1,SCLK2,DIN1,DIN2;
output alarm,alarm_low,locked_low,test_p,test_n;
output Gate_Ap,Gate_An,Gate_Bp,Gate_Bn;
output fault;
output [7:0] D;
output RS, RW, E; 
output [6:0] LED;
assign locked_low=standby? 1'b0:(~locked);
parameter jumper_off=1'b1;


//test standby
assign LED[6]=standby;
assign LED[5]=standby0;
assign LED[4]=locked;

wire alarm_low;
assign alarm_low=standby? clk1kHz:~alarm;

wire alarm;
assign alarm=clk0d6Hz & 1'b0;
wire fault;
assign fault=1'b0;

// ---------------Generate 10MHz, 14MHz and 100MHz clock signals ----------------//
//                    10 MHz for frequency locking control                       //
//                    14 MHz for ADC                                             //
//                    100MHz for three_pulses_PWM                                //
wire clk10MHz,clk20MHz,clk14MHz,clk100MHz;
clk_generator2 U1(.clk14MHz(clk14MHz),.clk100MHz(clk100MHz),.clk50MHz(clk50MHz)); 
clk_divided_by_5_60duty U2(.Out(clk20MHz),.In(clk100MHz));  
//-----------------------Standby/start tactile buttom----------------------------//
wire clk5MHz, clk1d25MHz,clk10kHz,clk5kHz, clk2d5kHz,clk1kHz, clk600Hz,clk300Hz;
wire clk9Hz,clk4Hz,clk1Hz, clk0d6Hz, clk0d3Hz;
assign clk10MHz=count[0];
assign clk5MHz =count[1];
assign clk1d25MHz=count[3];
assign clk10kHz=count[10];
assign clk5kHz =count[11];
assign clk2d5kHz=count[12];
assign clk1kHz =count[13];
assign clk600Hz=count[14];
assign clk300Hz=count[15];
assign clk9Hz=count[20];
assign clk4Hz=count[21];
assign clk1Hz=count[22];
assign clk0d6Hz=count[24];
assign clk0d3Hz=count[25];
reg [25:0] count;
reg [25:0] count_sweep;
reg sweep_flag=1'b0;
always @(posedge clk20MHz) 
begin
sweep_flag<=(count==26'd100)?1'd1:1'd0;
count<=count+1'b1;
//current_chang<=(sweep_flag==1'b1&&sweep==1'b1)?1'b1:1'b0;
end
reg debounce_switch=1'b0;
reg standby0=1'b1;  
always @(posedge clk1kHz) 	debounce_switch<=~SW;
always @(posedge debounce_switch) standby0 <=~standby0;
wire standby;  //jumper_off=no_PLC
assign standby=jumper_off?standby0:(~SW); //SW=start

wire transient;
assign transient=standby_d2&(~standby);
wire first_1s,second_1s,third_1s;
assign first_1s=standby_d2&(~standby);
assign second_1s=standby_d3&(~standby_d2);
assign third_1s=standby_d4&(~standby_d3);
reg standby_d,standby_d2,standby_d3, standby_d4;
always @(posedge clk1Hz) begin
    standby_d4<=standby_d3;
    standby_d3<=standby_d2;
    standby_d2<=standby_d;
	 standby_d<=standby;
end
//standby is controlled either by the tactil switch when 
//jumper_off=1 or by the PLC start signal when jumper_off=0;

//-----------------------Frequency Estimation----------------------------//
//   Inspired by 72/60e3*50e6 = 60e3, the estimatation of f is given by  //
//                     f_hat=2*60e3-72/f*50e6                            //
reg [6:0] count_cycle=7'b0;
wire [6:0] sum3;
assign sum3=count_cycle+1'b1;
wire count_to_72;
assign count_to_72=&{sum3[6],~sum3[5:4],sum3[3],~sum3[2:0]};  // 72='1001000'
always @(posedge cycle) count_cycle<=count_to_72? 7'b0:sum3;
wire flag=count_to_72_d&(~count_to_72_d2);
reg count_to_72_d,count_to_72_d2,count_to_72_d3;
always @(negedge clk50MHz_inv) begin
      count_to_72_d3<=count_to_72_d2;
      count_to_72_d2<=count_to_72_d;
		count_to_72_d<=count_to_72;
end

wire clk50MHz_inv;
assign clk50MHz_inv=~clk50MHz;
reg  [16:0] count_freq=17'b0;
wire [16:0] sum4;
assign sum4=count_freq+1'b1;
reg [16:0] count_result;
always @(posedge clk50MHz_inv) begin
      if (flag) begin
		    count_result<=sum4;
			 count_freq<=17'b0; end
		else
		    count_freq<=sum4;
end

parameter freq60kHzx2=17'b11101010011000000; //2*60e3
wire [16:0] freq;
assign freq= freq60kHzx2-count_result;
wire clk833Hz;
assign clk833Hz=count_to_72_d3;
wire [16:0] freq_smooth;
LPF3  U25(.out(freq_smooth),.in(freq),.clk(clk833Hz)); // cutoff=833*1.25/60=17 Hz
//-------------------------ADC get data-------------------------//
wire signed [12:0] data2;
wire channel,done2;
reg signed [12:0] Vo, Io, Io_temp, Io_1d5;
AD7322 U3(.data(data2),.channel(channel),.done(done2),.CS(CS2),
          .SCLK(SCLK2),.DIN(DIN2),.DOUT(DOUT2),.clk20MHz(clk14MHz));
always @(negedge done2) begin // read out @ negedge (data appears @ posedge)
  case(channel)
   1'b0: begin  Io_temp<= Io; 		Vo <= data2; 	end
	1'b1: begin  Io_1d5 <= Io_temp;  Io <= data2;   end
  endcase
end

wire signed [12:0] Io_1d25;
assign Io_1d25= {Io_1d5[12],Io_1d5[12:1]}+{{2{Io_1d5[12]}},Io_1d5[12:2]}
                +{{2{Io[12]}},Io[12:2]};
wire pulse340kHz,pulse340kHz_d,pulse340kHz_d2; //sample freq = 340kHz per channel  
assign pulse340kHz=(~sample_d2)&sample_d; 
assign pulse340kHz_d=(~sample_d3)&sample_d2;
assign pulse340kHz_d2=(~sample_d4)&sample_d3;      
reg sample_d,sample_d2,sample_d3,sample_d4 ;
always @(negedge clk14MHz) begin
	sample_d4<=sample_d3;
	sample_d3<=sample_d2;
	sample_d2<=sample_d;
	sample_d<=(~done2)&(~channel); // right after Vo being sampled
end

//-----------------------current level estimation-----------------------------//
wire[12:0] current_abs;
assign current_abs=(Io_1d25[12])?((~Io_1d25)+1'b1):Io_1d25;

reg[12:0] current_avg;	//average of 64 Io
reg[18:0] current_cum;
reg[5:0] current_count;

always@(posedge cycle)
begin
	current_count<=current_count+1'b1;
	if(current_count==6'b111111)
	begin
		current_avg<=current_cum[18:6];
		current_cum<=19'b0;
	end
	else
	begin
		current_avg<=current_avg;
		current_cum<=current_cum+current_abs;
	end
end

//--to smooth current--//

reg [10:0] a1, a2, a3, a4, a5, a6, a7;
wire [13:0] sum_a;
assign sum_a={{3{a7[10]}},a7}+{{3{a6[10]}},a6}+{{3{a5[10]}},a5}+{{3{a4[10]}},a4}
           +{{3{a3[10]}},a3}+{{3{a2[10]}},a2}+{{3{a1[10]}},a1}+{{3{current_avg[12]}},current_avg[12:2]};
reg [10:0] smooth_current;

always @(negedge clk300Hz) begin
	 a7<=a6;	 a6<=a5; a5<=a4;
	 a4<=a3; a3<=a2; a2<=a1; a1<=current_avg[12:2];
	 smooth_current<=sum_a[13:3];
end



//----------------------- Relay-Feedback Oscillator --------------------------//
//wire [4:0] n;
//assign n=5'b11001; //n=5'b11001.1 ;59864Hz;  5'b11010;  // 60kHz
//assign n=5'b10110;    // 59.36kHz
//assign n=5'b10101;  //21;  Set the free-running frequency equal to 20.1 kHz  
wire cycle;
//RFO2 U6(.y(cycle), .n(n), .r(r), .clk10MHz(clk10MHz));
//-------------------------------------//
//       new oscillator from UC        //
//  n_1=frequency*(2^24)/(50e6)  //
//-------------------------------------//
wire [14:0] n_ico;
parameter[14:0] start_point=15'd20199;	//20133=60kHz
													//20803=62kHz
reg [14:0]chang_point;						//20636=61.5kHz 
													//20300=60.5kHz 
													//20468=61kHz
													
reg [14:0]freq_sweep_chang=15'd17000;													
													
always@(posedge count[19])
begin
	freq_sweep_chang<=(freq_sweep_chang>=15'd24000)?freq_sweep_chang:freq_sweep_chang+15'd10;										
end												
													
													
//assign n_ico=freq_sweep_chang;													
//assign n_ico=PI_control+{7'b0,clk300Hz_d2,7'b0};	//with PI control
//assign n_ico=start_point+{6'b0,clk300Hz_d2,8'b0};	//no PI control, test delta
//assign n_ico=start_point;

//assign n_ico=(botton_count)?15'd16106:PI_control+{8'b0,clk300Hz_d2,6'b0};


//assign n_ico=chang_point;
//assign n_ico=(TX_FINISH)?start_point:chang_point;
//assign n_ico=(!TX_FINISH||LCD_begin)?chang_point:start_point;
//assign n_ico=(TX_FINISH)?PI_control+{6'b0,clk300Hz_d2,8'b0}:chang_point;

//assign n_ico=(sweep==1'd1)?start_point:(TX_FINISH)?PI_control+{6'b0,clk300Hz_d2,8'b0}:chang_point;


//assign n_ico=(!TX_FINISH||LCD_begin)?chang_point:(sweep==1'd1)?start_point:PI_control+{6'b0,clk300Hz_d2,8'b0};
assign n_ico=(!TX_FINISH||LCD_begin/*||LCD_lock*/)?chang_point:(sweep==1'd1||stop_freq==1'b1)?start_point:PI_control+{8'b0,clk300Hz_d2,6'b0};


//assign n_ico=(TX_FINISH)?start_point:chang_point;


ICO U6_1(.out(cycle), .increment(n_ico), .clk50MHz(clk50MHz));

//----------Three-Pulse PWM in syncrony with switching command cycle---------//
// Switch the transistors according to the pwm_in duty command from the      //
// power regulator.                                                          // 
// shutdown=1 : Shut down the transistors when level=0 or a fault occurs     //
//              or at standby.                                               //
wire [1:0] pwm_drive,pwm_out;
wire shutdown;
assign shutdown=standby;	//output control by sw 
assign pwm_drive=shutdown? 2'b0:pwm_out; 

parameter pwm_in=8'd130;	//output power

three_pulses_pwm2 U7(.pwm_drive(pwm_out),.in(pwm_in),.cycle(cycle),.clk100MHz(clk100MHz));

							

//---------------------------Dead Time = 0.52 us ----------------------------//
//      Convert the PWM commands pwm_drive[1:0] of two half bridges          //
//      into 4 switching commands for the H-bridge transistors:              //
//                                                                           //
//                  Gate_Ap, Gate_An, Gate_Bp, Gate_Bn                       //
//                                                                           //
//      with dead time equal to 0.52 us, 13 periods of a 25MHz clock.        //
reg clk25MHz;
always @(negedge clk50MHz) clk25MHz<=~clk25MHz; 
reg [3:0] k=4'b0;  
always @(negedge clk25MHz) k<=k+4'b0001; 			// present index k
wire [3:0] k_13;
assign k_13=k+4'b0011; 									// index k-13
wire   delayed_driveA,delayed_driveB;
assign delayed_driveA=delay_lineA[k_13];
assign delayed_driveB=delay_lineB[k_13];
reg [15:0] delay_lineA,delay_lineB;
reg Gate_Ap,Gate_An,Gate_Bp,Gate_Bn;

always @(posedge clk25MHz) begin
	  Gate_Ap<=pwm_drive[0]&delayed_driveA;
	  Gate_Bp<=pwm_drive[1]&delayed_driveB;
	  Gate_An<=~(pwm_drive[0]|delayed_driveA);
	  Gate_Bn<=~(pwm_drive[1]|delayed_driveB);
	  delay_lineA[k]<=pwm_drive[0];
	  delay_lineB[k]<=pwm_drive[1];
end

//-------------------Phase Regualtion with Tunable Delay---------------------//

reg locked_temp=1'b0;
wire locked;  
assign locked=&{locked_temp,~shutdown,~alarm};
wire [8:0] abs_theta_f;
assign abs_theta_f=theta_f[8]? (~theta_f+1'b1):theta_f;
parameter tolerance=9'b000000101;	// 5
wire signed [8:0] dead_zone;
assign dead_zone=abs_theta_f - tolerance;
reg [7:0] u=8'b0;
reg locked_previous=1'b0;
always @(posedge clk600Hz) begin  //clk600Hz
     if (dead_zone[8])   u<=u;
     else  u<=theta_f[8]?(u-1'b1):(u+1'b1);
		// abs_theta<=abs_theta+1;//{1'b0,count_level,3'b0};
		 locked_previous<=locked_temp;
end


//---------------Determine Frequency Locking or not---------------//
//              Comparator with hysteresis 45-16 deg              //
//              |theta|< 16  =>  locked_temp=1                    //
//              |theta|>= 45 =>  locked_temp=0                    //
//reg clk600Hz_d;
//always @(negedge clk20MHz) clk600Hz_d<=clk600Hz;
wire [8:0] abs_theta;
//assign abs_theta={1'b0,power_level,3'b0};
assign abs_theta=smooth_theta[8]? (~smooth_theta+1'b1):smooth_theta;
parameter theta_upper=9'b000101000; // 32+8
parameter theta_lower=9'b000010000; // 16
wire signed [8:0] lower_than_upper, lower_than_lower; 
assign lower_than_upper=abs_theta - theta_upper;
assign lower_than_lower=abs_theta - theta_lower;
always @(negedge clk600Hz) begin  //clk600Hz
     locked_temp<=locked_previous? lower_than_upper[8]:lower_than_lower[8]; 
end       //~|abs_theta[8:4]=1 when |theta|< 17 deg


//-------------------Digital Delay Line------------------------//

wire clk10MHz_inv;
assign clk10MHz_inv=~clk10MHz;
reg [7:0] kk;
always @(negedge clk10MHz_inv) kk<=kk+8'b00000001;
wire [7:0] kk_N_u,k1,k2;
parameter N=8'b01000100;//7'b1101000;  // 221
parameter shift=8'd60;
//parameter shift=8'b00001000;
assign kk_N_u=kk-u;//-{1'b0,u};  kk_N_u=kk-N-u;
assign k1=kk-8'b00100000+shift;  		  //kk-32
assign k2=kk-8'b01001010+shift;  		  //kk-74
wire delayed_Iq;
assign delayed_Iq=delay_line_Iq[kk_N_u];
wire Iq,Vq,Is,Is_d;
assign Is=delay_line_Iq[k1];
assign Is_d=delay_line_Iq[k2]; 		  // additional delay by T/4
reg Iqq,Vs;
always @(negedge clk50MHz) begin
         Iqq<=Iq;
			Vs<=Vq;
end

reg [255:0] delay_line_Iq;
reg r;
always @(posedge clk10MHz_inv) begin
		delay_line_Iq[kk]<=Iqq;  			// digital delay line
		r<=~delayed_Iq;
end
//----------------------Phase Estimation----------------------//
//    theta=+-177 correspond to +-180 degree,respectively,    //
//    where 177=167+167/16, with 167=10e6/60e3 being the      //
//    count number in one cycle, and + meaning V leads I.     //                                  // 
wire signed [8:0] sum_VI_corrected;  
assign sum_VI_corrected=sum_VI+{4'b0,sum_VI[8:4]};                        
reg signed [8:0] theta,theta_n,sum_VI,sum_VI_d; 
always @(posedge clk10MHz_inv) begin
      if (pulse60kHz) begin
			 theta_n<=sum_VI;
		    theta<=sum_VI_d[8]? (~sum_VI+9'b000000001):sum_VI;
			 sum_VI<=9'b0;
			 sum_VI_d<=9'b0; end
		else begin
		    sum_VI<=(!cycle^Is)? (sum_VI+1'b1):sum_VI;	//use cycle to replace Vs
			 sum_VI_d<=(!cycle^Is_d)? (sum_VI_d+1'b1):(sum_VI_d-1'b1); end 
end
wire signed [8:0] theta_f;
LPF1d25kHz U8(.out(theta_f),.in(theta),.clk60kHz(pulse60kHz_d));

//--to smooth theta--//

reg signed [8:0] b1, b2, b3, b4, b5, b6, b7;
wire signed [11:0] sum_b;
assign sum_b={{3{b7[8]}},b7}+{{3{b6[8]}},b6}+{{3{b5[8]}},b5}+{{3{b4[8]}},b4}
           +{{3{b3[8]}},b3}+{{3{b2[8]}},b2}+{{3{b1[8]}},b1}+{{3{theta_f[8]}},theta_f};
reg signed [8:0] smooth_theta;

always @(negedge clk2d5kHz) begin
	 b7<=b6;	 b6<=b5; b5<=b4;
	 b4<=b3; b3<=b2; b2<=b1; b1<=theta_f;
	 smooth_theta<=sum_b[11:3];  //2.5kHz/8=312.5 Hz
end


//-----PI contorl start-------//

//test the phase direct//
reg clk300Hz_d1,clk300Hz_d2;
always@(posedge clk5MHz)
begin
	clk300Hz_d1<=clk300Hz;
	clk300Hz_d2<=clk300Hz_d1;
end

wire clk300Hz_pulse;	//rise at negedge of clk300Hz_d1, use for change n_ico
assign clk300Hz_pulse=(~clk300Hz_d1)&clk300Hz_d2;


reg TX=1'b1;
reg TX_FINISH=1'b1;
reg[19:0]TX_count_bit=20'b0;
reg[8:0]TX_out;
reg[12:0]TX_data;
reg[5:0]TX_choose=6'b0;
reg LCD_begin=1'b0;
reg LCD_lock=1'b0;


//output reg [1:0]test=2'd1;  
reg [9:0]LCD_lock_count=10'd0;
reg [9:0]LCD_begin_count=10'd0;
reg [9:0]TX_FINISH_count=10'd0;
reg [9:0]stop_freq_count=10'd0;

reg sweep=1'd0;
reg chang;
reg sweep_delay;
reg delay_chang;

wire LCD_sweep;
wire LCD_run;
wire LCD_LOCK;
wire LCD_OFF;
wire [3:0]LCD_freq_cho;

reg run=1'b0;
reg OFF=1'b0;
reg LOCK=1'b0;
reg [3:0]freq_cho=4'd0;
reg current_chang=1'b0;
reg[14:0]map_current;

reg stop_freq=1'b1;
reg stop_freq_flag;
reg [1:0]lock_state=2'b0;

always@(negedge clk20MHz) 
begin
	
	
	current_chang<=(TX_FINISH_count==10'd90&&sweep==1'b1)?1'b1:1'b0;
	stop_freq<=(TX_choose==6'd24&&stop_freq_flag==1'd1)?1'b0:(TX_choose==6'd0||TX_choose==6'd1||TX_choose==6'd13)?1'b1:stop_freq;
	
	
	///////////////////////sweep/////////////////////////////
	
	if(LCD_sweep==1'b1) 		begin	sweep<=1'b1;run<=1'b0;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd0;TX_choose<=6'd0;end
	
	
	else if(SW2==1'b0) 		begin	sweep<=1'b1;run<=1'b0;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd0;TX_choose<=6'd0;end
	
		
	else if(sweep_flag==1'b1&&sweep==1'b1)
		begin
		
		if(TX_choose==6'd13)
			begin TX_choose<=TX_choose;sweep<=1'd0;chang<=chang;end
		else 
			begin TX_choose<=TX_choose+6'd1;sweep<=sweep;chang<=~chang; end
		end
	
	
	/////////////////begin///////////////////////////////////	
	else if(LCD_run==1'b1)	begin	sweep<=1'b0;run<=1'b1;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd0;TX_choose<=6'd1;end
	
	/////////////////OFF/////////////////////////////////////	
	else if(LCD_OFF==1'b1)	begin	sweep<=1'b0;run<=1'b0;OFF<=1'b1;LOCK<=1'b0;freq_cho<=4'd0;TX_choose<=6'd13;end
	
	/////////////////LOCK/////////////////////////////////////
	else if(LCD_LOCK==1'b1)	begin	sweep<=1'b0;run<=1'b0;OFF<=1'b0;LOCK<=1'b1;freq_cho<=4'd0;TX_choose<=6'd24;end
	
	/////////////////30k///////////////////////////////////	
	else if(LCD_freq_cho==4'd1)	begin	sweep<=1'b0;run<=1'b1;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd2;TX_choose<=6'd2;end
	
	/////////////////31k///////////////////////////////////	
	else if(LCD_freq_cho==4'd2)	begin	sweep<=1'b0;run<=1'b1;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd15;TX_choose<=6'd15;end
	
	/////////////////32k///////////////////////////////////
	else if(LCD_freq_cho==4'd3)	begin	sweep<=1'b0;run<=1'b1;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd4;TX_choose<=6'd4;end
	
	/////////////////33k///////////////////////////////////	
	else if(LCD_freq_cho==4'd4)	begin	sweep<=1'b0;run<=1'b1;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd5;TX_choose<=6'd5;end
	
	/////////////////34k///////////////////////////////////	
	else if(LCD_freq_cho==4'd5)	begin	sweep<=1'b0;run<=1'b1;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd6;TX_choose<=6'd6;end
	
	/////////////////35k///////////////////////////////////	
	else if(LCD_freq_cho==4'd6)	begin	sweep<=1'b0;run<=1'b1;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd7;TX_choose<=6'd7;end
	
	/////////////////36k///////////////////////////////////	
	else if(LCD_freq_cho==4'd7)	begin	sweep<=1'b0;run<=1'b1;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd8;TX_choose<=6'd8;end
	
	/////////////////37k///////////////////////////////////
	else if(LCD_freq_cho==4'd8)	begin	sweep<=1'b0;run<=1'b1;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd9;TX_choose<=6'd9;end
	
	/////////////////38k///////////////////////////////////	
	else if(LCD_freq_cho==4'd9)	begin	sweep<=1'b0;run<=1'b1;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd10;TX_choose<=6'd10;end
	
	/////////////////39k///////////////////////////////////	
	else if(LCD_freq_cho==4'd10)	begin	sweep<=1'b0;run<=1'b1;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd11;TX_choose<=6'd11;end
	
	/////////////////40k///////////////////////////////////	
	else if(LCD_freq_cho==4'd11)	begin	sweep<=1'b0;run<=1'b1;OFF<=1'b0;LOCK<=1'b0;freq_cho<=4'd12;TX_choose<=6'd12;end
	
	
	else 
		begin	run<=(LCD_begin_count>=10'd28)?1'd0:run;  OFF<=(LCD_begin_count>=10'd28)?1'd0:OFF;  LOCK<=(LCD_begin_count>=10'd28)?1'd0:LOCK;  freq_cho<=(LCD_begin_count>=10'd28)?4'd0:freq_cho; TX_choose<=TX_choose;end
	
	
	
	
end


reg botton_count;
reg SW2_delay;


//always@(posedge clk50MHz) 
always@(posedge count[18]) 
begin


	SW2_delay<=SW2;
	if(SW2_delay==1'd1&&SW2==1'd0)begin botton_count<=botton_count+1'd1;end
	


	delay_chang<=chang;
	TX_FINISH_count<=(chang^delay_chang==1'd0&&sweep==1'd1)?TX_FINISH_count+10'd1:10'd0;
	TX_FINISH<=(TX_FINISH_count<=10'd27&&sweep==1'd1)?0:1;
	
	

	

	LCD_begin_count<=(run==1'd1||OFF==1'd1||LOCK==1'd1||freq_cho!=4'd0)?LCD_begin_count+10'd1:10'd0;
	LCD_begin<=(LCD_begin_count<=10'd28&&(run==1'b1||OFF==1'b1||LOCK==1'd1||freq_cho!=4'd0))?1'd1:1'd0;				
		
	
	stop_freq_count<=(TX_choose==6'd24)?(stop_freq_count<=10'd100)?stop_freq_count+10'd1:stop_freq_count:10'd0;
	stop_freq_flag<=(stop_freq_count>=10'd30)?1'd1:1'd0;
	
	
	
	
	
//	LCD_lock_count<=(LOCK==1'b1&&LCD_lock_count<=10'd50)?LCD_lock_count+10'd1:10'd0;
//	LCD_lock<=(LOCK==1'b1&&LCD_begin_count<=10'd27)?1'd1:1'd0;
//	lock_state<=(lock_state==2'd3)?2'd0:(LOCK==1'b1&&LCD_lock_count==10'd29)?lock_state+2'd1:lock_state;
	

//	TX_FINISH_count<=(TX_FINISH_count==10'd228)?10'd0:TX_FINISH_count+10'd1;
//
//	TX_FINISH<=(TX_FINISH_count<=10'd200)?1:0;
	
	
	

	case (TX_choose)
		6'd2:begin  TX_data<=13'b0101010101011; end		//30kHz		0
		6'd14:begin  TX_data<=13'b0101010101101; end		//30.5kHz	1
		6'd3:begin  TX_data<=13'b0101010110011; end		//31kHz		2
		6'd15:begin  TX_data<=13'b0101010110101; end		//31.5kHz	3
		6'd4:begin  TX_data<=13'b0101011001011; end		//32kHz		4
		6'd16:begin  TX_data<=13'b0101011001101; end		//32.5kHz	5
		6'd5:begin  TX_data<=13'b0101011010011; end		//33kHz		6
		6'd17:begin  TX_data<=13'b0101011010101; end		//33.5kHz	7
		6'd6:begin  TX_data<=13'b0101100101011; end		//34kHz		8
		6'd18:begin  TX_data<=13'b0101100101101; end		//34.5kHz	9
		6'd7:begin  TX_data<=13'b0101100110011; end		//35kHz		10
		6'd19:begin  TX_data<=13'b0101100110101; end		//35.5kHz	11
		6'd8:begin  TX_data<=13'b0101101001011; end		//36kHz		12
		6'd20:begin  TX_data<=13'b0101101010011; end		//36.5kHz	13
		6'd9:begin  TX_data<=13'b0101101010101; end		//37kHz		14
		6'd21:begin  TX_data<=13'b0110010101011; end		//37.5kHz	15
		6'd10:begin  TX_data<=13'b0110010101101; end		//38kHz		16
		6'd22:begin  TX_data<=13'b0110010110011; end		//38.5kHz	17
		6'd11:begin  TX_data<=13'b0110010110101; end		//39kHz		18
		6'd23:begin  TX_data<=13'b0110011001011; end		//39.5kHz	19
		6'd12:begin  TX_data<=13'b0110011001101; end		//40kHz		20
		6'd1:begin  TX_data<=13'b0110011010011; end		//RUN 		21
		6'd13:begin  TX_data<=13'b0110011010101; end		//stop		22
		6'd0:begin  TX_data<=13'b0110100101011; end		//SWEEP		23
		6'd24:begin  TX_data<=13'b0110100101101; end		//LOCK  		24
		default:	begin  TX_data<=13'b1111111111111; end
	endcase

	
	
	
	
	if(TX_FINISH==1'b0||LCD_begin==1'b1/*||LCD_lock==1'b1*/)
	begin
		if(TX_count_bit==20'd13)
		begin
			TX<=0;
			TX_count_bit<=20'b0;
//			TX_FINISH<=(SW2==1)?1:0;
		end
		else
		begin
			TX_count_bit<=TX_count_bit+20'd1;
			TX<=TX_data[TX_count_bit];
		end
		
		
		chang_point=(TX)?15'd20200:15'd20300;
		
	end
	
end



wire signed[8:0] theta_3deg;
assign theta_3deg=theta-3'd15;
reg signed[8:0] theta_past,theta_f_past;

always@(posedge clk300Hz)
begin
	//want to lock at about angle +3 deg
	theta_past<=(theta_3deg[8])?(~theta_3deg+9'b000000001):theta_3deg;
	theta_f_past<=theta_3deg;
	/*
	theta_past<=theta_n;
	theta_f_past<=theta;
	*/
end

reg signed [8:0] delta,delta_f;
always@(negedge clk300Hz)
begin
	//want to lock at about angle +3 deg
	delta<=(theta_3deg[8])? (theta_past-(~theta_3deg+9'b000000001)):(theta_past-theta_3deg);
	delta_f<= theta_f_past-theta_3deg;
	/*
   delta<= theta_past-theta_n;
	delta_f<= theta_f_past-theta;
	*/
end

wire[8:0] delta_d;
assign delta_d=(delta_f[8])?(~delta+9'b000000001):delta;

////////////////


wire signed [16:0] temp_accum_I;
assign temp_accum_I = accum_I + {{7{delta[8]}},delta,1'b0};	//I factor
reg signed [16:0] accum_I={start_point,2'b0};

always@(posedge clk300Hz_pulse) 
begin 
	// accumulator for integration
	accum_I <= temp_accum_I;  
end

reg [14:0] PI_control=start_point;
always@(negedge clk300Hz_pulse) 
begin
   // Round off two bits  
   PI_control<= temp_accum_I[16:2];
end

//-----PI contorl end-------//	

//-----------------Edge detection for a cycle-----------------//
//  Generate pulses to indicate the beginning of each cycle   //
wire pulse60kHz, pulse60kHz_d,pulse60kHz_d2;   
assign pulse60kHz=(~cycle_d2)&cycle_d; 
assign pulse60kHz_d=(~cycle_d3)&cycle_d2;
assign pulse60kHz_d2=(~cycle_d4)&cycle_d3;      
reg cycle_d,cycle_d2,cycle_d3,cycle_d4 ;
always @(negedge clk10MHz_inv) begin
	cycle_d4<=cycle_d3;
	cycle_d3<=cycle_d2;
	cycle_d2<=cycle_d;
	cycle_d<=cycle;
end


//-------------------------LCD Display----------------------------------//
reg RW;
always @(posedge clk50MHz) RW<=1'b0;
wire RWW,E, RS;
wire [7:0] D;
wire RST=1'b1;
wire ON;
wire [4:0] status;
assign status={locked,4'b0};
LCD_display U9(.status(status),.freq(freq_display),.theta(theta_display),
            .power(power_display),.CLK(clk20MHz),.slowCLK(clk0d6Hz),.RESET(RST),
				.LCM_RW(RWW),.LCM_EN(E),.LCM_RS(RS),.LCM_DATA(D),.LCD_ON(ON));
				 
reg [8:0] theta_display;
reg [10:0] power_display;
reg [15:0] freq_display;
always @(posedge clk4Hz) begin
          freq_display<=shutdown? 16'b1110101001100000:freq_smooth[15:0];
			 theta_display<=shutdown? 9'b0:smooth_theta;
			 power_display<=shutdown? 11'b0:{1'b0,smooth_current[10:1]};
end
	
//---------------------test point-----------------------------------------//	
wire test_p,test_n;
assign test_p=Vs;//locked_temp;//standby? Gate_Ap:Gate_Bp;//Iq;//u[8];//Vq;//standby? Gate_Ap1:Gate_Bp1;
assign test_n=Is;//standby? Gate_An:Gate_Bn;//Vq;//delayed_Iq;//u[7];//Iq;//standby? Gate_An1:Gate_Bn1;

//----------------------------LCD-----------------------------------------//

output LCD_csn,LCD_clk,LCD_INT,LCD_PD;
inout LCD_out0,LCD_out1,LCD_out2,LCD_out3;

LCD LCD1(.clk50M(clk50MHz),.clk20MHz(clk20MHz),
			.out0(LCD_out0),.out1(LCD_out1),.out2(LCD_out2),.out3(LCD_out3),
			.cs_n(LCD_csn),.out_clk(LCD_clk),.INT(LCD_INT),.PD(LCD_PD),
			.sweep(LCD_sweep),.LOCK(LCD_LOCK),.run(LCD_run),.OFF(LCD_OFF),.freq_cho(LCD_freq_cho),.current_flag(current_chang),.current(smooth_current),.TX_choose(TX_choose));










endmodule

