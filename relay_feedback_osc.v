module relay_feedback_osc(test_n,test_p,LED,
					  Gate_Ap,Gate_Bp,SD,
					  Vq,Iq,SW,CS2,SCLK2,DIN2,DOUT2,
					  RS,RW,E,D,clk50MHz);
					  
input SW,Vq,Iq,clk50MHz,DOUT2;
parameter jumper_off=1'b1;
output CS2,SCLK2,DIN2;
output test_p,test_n;
output Gate_Ap,Gate_Bp,SD;
output [7:0] D;
output RS, RW, E; 
output [2:0] LED;


//test standby
assign LED[2]=standby;
assign LED[1]=standby0;
assign LED[0]=locked;

parameter alarm=1'b0;
parameter fault=1'b0;

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
always @(posedge clk20MHz) count<=count+1'b1;
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
//-------------------------Power Estimation-------------------------//
wire signed [12:0] data2;
wire[1:0] channel;
wire done2;
	
reg signed [12:0] Vo, Io, Io_temp, Io_1d5,PH,PO;
AD7322 U3(.data(data2),.channel(channel),.done(done2),.CS(CS2),
          .SCLK(SCLK2),.DIN(DIN2),.DOUT(DOUT2),.clk20MHz(clk14MHz));
			 
always @(negedge done2) begin // read out @ negedge (data appears @ posedge)
  case(channel)
   2'b00: begin  Io_temp<= Io; 		Vo <= data2; 	end
	2'b01: begin  PH<= data2;   end
	2'b10: begin  Io_1d5 <= Io_temp;  Io <= data2; 	end
	2'b11: begin  PO <= data2; 	end
  endcase
end

wire signed [12:0] Io_1d25;
assign Io_1d25= {Io_1d5[12],Io_1d5[12:1]}+{{2{Io_1d5[12]}},Io_1d5[12:2]}
                +{{2{Io[12]}},Io[12:2]};
	
//----------------Get Current Level-----------------//

wire[11:0] Io_1d25_abs;	//absolute of Io_1d25
assign Io_1d25_abs=(Io[12])?(~Io[11:0]+1'b1):Io[11:0];


reg[25:0] Io_accum;
reg[11:0] Io_sum;
reg[13:0] Io_count;

wire done_Io_count;
assign done_Io_count=&Io_count;	//sum 4096 Io_1d25_abs

always@(posedge done2)
begin
	Io_count<=Io_count+1'b1;
	if(done_Io_count)
	begin
		Io_sum<=Io_accum[25:14];
		Io_accum<=26'b0;
	end
	else
	begin
		Io_sum<=Io_sum;
		Io_accum<=Io_accum+Io_1d25_abs;
	end
end


//----------------Get Current Level-----------------//	
					 
wire pulse340kHz,pulse340kHz_d,pulse340kHz_d2; //sample freq = 340kHz per channel  
assign pulse340kHz=(~sample_d2)&sample_d; 
assign pulse340kHz_d=(~sample_d3)&sample_d2;
assign pulse340kHz_d2=(~sample_d4)&sample_d3;      
reg sample_d,sample_d2,sample_d3,sample_d4 ;
always @(negedge clk14MHz) begin
	sample_d4<=sample_d3;
	sample_d3<=sample_d2;
	sample_d2<=sample_d;
	sample_d<=(~done2)&(channel==2'b01); // right after Vo being sampled
end
//--------------------- Instantaneous Power --------------------//
wire signed [25:0] IV;
mult U_IV(.clock(~pulse340kHz),.dataa(Vo), .datab(Io_1d25), .result(IV));
reg  signed [31:0] accum=32'b0;
wire signed [31:0] summation;
assign summation=accum+{{6{IV[25]}},IV};
reg  signed [31:0] total_power=32'b0;
wire done_accum;//340kHz/64=5.3kHz
assign done_accum=&count_accum;
reg [5:0] count_accum=6'b0;  // sum of 64 instantaneous powers
always @(posedge pulse340kHz_d2) begin
     count_accum<=count_accum+6'b000001;
	  if (done_accum) begin
	        total_power<=summation;
			  accum<=32'b0; end
	  else begin
	        total_power<=total_power;
	        accum<=summation; end
end
wire signed [23:0] power, ave_power;                
assign ave_power=total_power[31:8];  //cutoff=1.25/60*5.3kHz=110Hz
LPF2 U155Hz(.out(power),.in(ave_power),.clk(~done_accum)); 
wire [10:0] power32;//[9:0] power32;
assign power32=power[23]?(~power[17:7]+1'b1):power[17:7];// 6 bits of fractional number //power[17:8];  
// Power estimator output is 10-bit power32, among them there are
// 5 digits for whole number and 5 digits for fractional number.
// ex. power=0.5 Watt => power32= 10'b 00000 10000, namely 
// power32 divided by 32 to get the estimated power in Watt.
// power command = {2'b0,power_level,4'b0}


//--------------------------Power Regulation--------------------------------//
//         1) Transducer amplitude Dynamics: roughly 300 Hz                 //
//         2) Power estimation delay: 1/5.3kHz=1.89e-4 s                    //
//         3) Power estimation filtering: cutoff=110 Hz                     //
//                                                                          //
//             C(z) = (1/8)+(1/4)/(1-z^-1), fs = 332 Hz                     //
//             GM= 42 dB, PM=85 degrees                                     //

reg [3:0] count3;
always @(posedge done_accum) count3<=count3+1'b1;
reg clk332Hz, clk332Hz_d, clk332Hz_d2;
always @(posedge clk14MHz) begin
     clk332Hz_d2 <= clk332Hz_d;
     clk332Hz_d <= clk332Hz;
	  clk332Hz   <= count3[3];
end
//
//
////wire [8:0] set_point;
////assign set_point=no_PLC? {power_level,4'b0}:setpoint_PLC;
//wire [9:0] power_command;
//LPF0 U100Hz(.out(power_command),.in(setpoint),.clk60kHz(~clk5kHz));
//reg [9:0] c1, c2, c3, c4, c5, c6, c7;
//wire [12:0] sum_c;
//assign sum_c={3'b0,c7}+{3'b0,c6}+{3'b0,c5}+{3'b0,c4}
//           +{3'b0,c3}+{3'b0,c2}+{3'b0,c1}+{3'b0,power_command};
//reg [9:0] smooth_power_command;
//
//always @(posedge clk332Hz) begin
//	 c7<=c6;	 c6<=c5; c5<=c4;
//	 c4<=c3; c3<=c2; c2<=c1; c1<=power_command;
//	 smooth_power_command<=sum_c[12:3];  // 332Hz/8 = 41.5 Hz
//end	
//
//
//parameter initial_duty=8'b1111000; // 120
//wire signed [11:0] err;
//assign  err={1'b0,power32}-{2'b0,smooth_power_command}; // 9-bit power_command < 16 W (only 4 bit for integer)
//reg signed  [11:0] uI4={1'b0,initial_duty,3'b0};					
//always @(posedge clk332Hz_d) begin
//       uI4 <= locked? (uI4+err+windup_err):uI4;//{1'b0,initial_duty,2'b0};
//end
//wire signed [11:0] u4;
//assign u4=uI4+{{2{err[11]}},err[11:2]}+{{3{err[11]}},err[11:3]};
//
//parameter lower_bound=8'b0;
//parameter upper_bound=8'b10001100;  // 140
//wire signed [11:0] upper_err,lower_err;
//assign upper_err={1'b0,upper_bound,3'b0}-u4;
//assign lower_err={1'b0,lower_bound,3'b0}-u4;
//reg [7:0] pwm_in=initial_duty;
//reg signed [11:0] windup_err;
//always @(posedge clk332Hz_d2) begin
//    if (upper_err[11]==1) begin
//	      windup_err<={{2{upper_err[11]}},upper_err[11:2]};
//			pwm_in<=upper_bound;  								end
//	 else if (lower_err[11]==0) begin
//	      windup_err<={{2{lower_err[11]}},lower_err[11:2]};
//			pwm_in<=lower_bound;    			 				end
//	 else  begin
//			pwm_in<=u4[10:3];//locked? u4[9:2]:initial_duty; 
//			windup_err=11'b0;  								  	end
//end

//---------------------------Fault Detection--------------------------------//
//                    Open, Short, No_locking Detection                     //
 
//  (1) Load Impedance Estimation
//  integrate abs(Io) and abs(Vo) in four cycles of driving frequency 60kHz 
//   high_impdenace=1 when sum|Io| < sum|Vo|/32;(higher than 2kohms)
//  low_impedance =1 when sum |Io| > sum 4|Vo|; (lower than 10 ohms)
reg [1:0] count_cycles=2'b0;
wire four_cycles;
assign four_cycles=&count_cycles;
always @(posedge pulse60kHz)  count_cycles<=count_cycles+1'b1;
reg four_cycles_d,four_cycles_d2,four_cycles_d3,four_cycles_d4;
always @(posedge pulse340kHz) begin
    four_cycles_d4<=four_cycles_d3;
    four_cycles_d3<=four_cycles_d2;
	 four_cycles_d2<=four_cycles_d;
	 four_cycles_d<=four_cycles;
end
wire pulse_four_cycles,pulse_four_cycles_d,pulse_four_cycles_d2;
assign pulse_four_cycles=four_cycles_d&(~four_cycles_d2);
assign pulse_four_cycles_d=four_cycles_d2&(~four_cycles_d3);
assign pulse_four_cycles_d2=four_cycles_d3&(~four_cycles_d4);

wire signed [12:0] abs_Io, abs_Vo;
assign abs_Io=Io[12]? (~Io+1'b1):Io;
assign abs_Vo=Vo[12]? (~Vo+1'b1):Vo; 
reg signed [17:0] accum_abs_Io, accum_abs_Vo;
reg signed [12:0] sum_abs_Io, sum_abs_Vo;
always @(posedge pulse340kHz_d) begin
      if (pulse_four_cycles) begin
		    sum_abs_Io<=accum_abs_Io[17:5];
			 sum_abs_Vo<=accum_abs_Vo[17:5];
			 accum_abs_Io<=18'b0;
			 accum_abs_Vo<=18'b0; end
		else begin
		    accum_abs_Io<=accum_abs_Io+abs_Io;
			 accum_abs_Vo<=accum_abs_Vo+abs_Vo; end 
end
wire signed [12:0] sum_abs_Io_f, sum_abs_Vo_f;
LPF4 UU8(.out(sum_abs_Io_f),.in(sum_abs_Io),.clk(pulse_four_cycles_d));
LPF4 UU9(.out(sum_abs_Vo_f),.in(sum_abs_Vo),.clk(pulse_four_cycles_d));

wire signed [14:0] diff1;
assign diff1={sum_abs_Vo_f,2'b0}-{2'b0, sum_abs_Io_f};  //negative when sum|Io| > sum 4|Vo|; (lower than 10 ohms)
wire signed [14:0] diff2;
assign diff2={sum_abs_Io_f,2'b0}-{7'b0, sum_abs_Vo_f[12:5]}; // negative when sum|Io| < sum|Vo|/64;(higher than 8 kohms)
reg low_impedance=1'b0;
reg low_impedance0=1'b0;
reg high_impedance=1'b0;
reg high_impedance0=1'b0;
always @(posedge pulse_four_cycles_d) begin 
    low_impedance0  <= low_impedance;
    high_impedance0 <= high_impedance;
end
always @(posedge pulse_four_cycles_d2) begin
    if (standby|transient) begin
	      low_impedance  <= 1'b0;
			high_impedance <= 1'b0; end
	 else begin
	      low_impedance  <= (low_impedance0|diff1[14]); //low_impedance =1 when Io > 4*Vo; (lower than 10 ohms)
         high_impedance <= (high_impedance0|diff2[14]);//high_impdenace=1 when Io < Vo/32;(higher than 2kohms)
    end
end

// no_locking=1 when locked=0 lasts for more than 1 second
wire [12:0] sum_no_locking;
assign sum_no_locking=count_no_locking+{12'b0,~locked};
wire sure_no_locking;
assign sure_no_locking=&sum_no_locking;
reg [12:0] count_no_locking=13'b0;
wire clear_count;
assign clear_count=shutdown|locked|transient;
always @(posedge pulse_four_cycles_d) begin
     no_locking0<=no_locking;
     if (clear_count) count_no_locking<=13'b0;
	  else  count_no_locking<=sure_no_locking? count_no_locking:sum_no_locking;
end
reg no_locking0=1'b0;
reg no_locking=1'b0;
always @(posedge pulse_four_cycles_d2) begin
     if (standby|transient) no_locking<= 1'b0;
	  else         no_locking<= (no_locking0|sure_no_locking);
end

//parameter threashold=14'b00110100000000; //3328 (9.75V)
//wire signed [13:0] diff3;
//assign diff3=threashold-{ave_power_set[12],ave_power_set};
//wire no_command0;
//assign no_command0=diff3[13];
//reg no_command;
//always @(standby) no_command<=no_command0&(~standby);
//reg alarm_temp=1'b0;
//always @(negedge pulse_four_cycles_d2) alarm_temp<=|{no_command,low_impedance,high_impedance,no_locking};

//no use
//
//
////------------To determine the power level and display it on LED---------------//
//// Power level set by the PLC/pot when jumper_off = 0/1 with/no jumper across  // 
//// PIN_34 and GND:                                                             //
////                                                                             //
//// level   :  0	 1	   2	  3    4	   5	  6	 7 	8	  9	 10   11    12  //
//// power(W):  0  0.5  1.2  1.5  1.8  2.1  2.3  2.5  2.7  2.9   3.1  3.2   3.3  //
////                                                                             //
//// level   : 13   14   15   16   17   18   19   20   21   22    23   24        //
//// power(W):3.4  3.5  3.6  3.7  3.9  4.2  4.5  5.0  5.5  6.0   7.0  8.0        //
//
//wire signed [12:0] data1;
//wire set_by_which,done1;
//reg signed [12:0] power_set_pot, power_set_PLC;
//
////use AD7323 4-channel
///*
//AD7322 U4(.data(data1),.channel(set_by_which),.done(done1),.CS(CS1),
//          .SCLK(SCLK1),.DIN(DIN1),.DOUT(DOUT1),.clk20MHz(clk1d25MHz));
//
//always @(negedge done1) begin // read out @ negedge (data appears @ posedge)
//  case(set_by_which)
//   1'b0: power_set_pot <= data1;
//	1'b1: power_set_PLC <= data1;
//  endcase
//end
//*/
//
//wire no_PLC;
//assign no_PLC=jumper_off;
//reg signed [12:0] power_set;
//always @(negedge clk300Hz) power_set<=no_PLC? power_set_pot:power_set_PLC;
//wire signed [12:0] ave_power_set;  	// cutoff=1.25kHz/60kHz*300Hz=6.25Hz
//LPF4 U6d25Hz2(.out(ave_power_set),.in(power_set),.clk(clk300Hz)); 
////begin
////  	if (first_1s|third_1s)  power_set<=13'b0110110011000;//13'b0111000010100;//13'b0111001100110;   // 9/10*4096
////	else if (second_1s) power_set<=no_PLC? power_set_pot:power_set_PLC;
////	else power_set<=no_PLC? power_set_pot:power_set_PLC;
////end
//
//
//
//
//wire signed [13:0] shifted_power_level;
//assign shifted_power_level={ave_power_set[12],ave_power_set}+14'b00110111001101;//+3533=(12-3.375)/10*4096  
//                                                           //14'b00110100010100; '00000010011001'                                                      
//parameter increment=14'b00000100110011; //307=0.75/10*4096;
//reg signed [13:0]  sweep_level=14'b0;
//wire signed [13:0] sum_level;
//assign sum_level=shifted_power_level-sweep_level;
//reg [4:0] count_level_0=5'b0;
//reg [4:0] level=5'b0; 
//wire initial_high;
//assign initial_high=first_1s|third_1s;
//wire FS;
//assign FS=(count_level_0==24);
//reg no_command0=1'b0;
//always @(posedge clk5kHz) begin
//    if (sum_level[13]) begin
//	       level <= initial_high? 5'b11000:count_level_0;
//	       sweep_level<=14'b0;
//			 count_level_0<=5'b0; 
//			 no_command0<=1'b0; end
//	 else if (FS) begin 
//	       level <= 5'b0;
//			 sweep_level<=14'b0;
//			 count_level_0<=5'b0; 
//			 no_command0<=1'b1; end
//			 
//	 else begin
//	       sweep_level<=sweep_level+increment;
//			 count_level_0<=(count_level_0+1'b1); end
//
//end
//wire [9:0] setpoint;
//assign setpoint=desired_power[level];  
//
//reg [9:0] desired_power[24:0];
//initial $readmemb("power_level_PLC2.txt",desired_power,0,24);   

		 

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
parameter[14:0] start_point=15'd20133;	//20133=60kHz  20803=62kHz

assign n_ico=PI_control+{7'b0,clk300Hz_d2,7'b0};	//with PI control
//assign n_ico=start_point+{6'b0,clk300Hz_d2,8'b0};	//no PI control, test delta
//assign n_ico=start_point;
ICO U6_1(.out(cycle), .increment(n_ico), .clk50MHz(clk50MHz));

//----------Three-Pulse PWM in syncrony with switching command cycle---------//
// Switch the transistors according to the pwm_in duty command from the      //
// power regulator.                                                          // 
// shutdown=1 : Shut down the transistors when level=0 or a fault occurs     //
//              or at standby.                                               //
wire [1:0] pwm_drive,pwm_out;
wire shutdown;
//assign shutdown=1'b0; //always turn on
assign shutdown=standby;	//output control by sw
//assign shutdown=|{standby,(~|level),alarm_temp};
 
assign pwm_drive=shutdown? 2'b0:pwm_out; 
three_pulses_pwm2 U7(.pwm_drive(pwm_out),.in(8'd35),.cycle(cycle),
//three_pulses_pwm2 U7(.pwm_drive(pwm_out),.in(pwm_in),.cycle(cycle),
                     .clk100MHz(clk100MHz));


//assign SD=(standby)?1'b1:(!pwm_drive[0]);
assign SD=(standby);
//assign SD=1'b1; //for test							
							
//no dead time							
reg Gate_Ap,Gate_Bp;
reg clk25MHz;
always @(negedge clk50MHz) clk25MHz<=~clk25MHz;
always @(posedge clk25MHz) begin
	  Gate_Ap<=(pwm_drive[1])?pwm_drive[0]:1'b0;
	  Gate_Bp<=(!pwm_drive[1])?pwm_drive[0]:1'b0;
end							
							
/*							

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
//reg t_Gate_Ap,t_Gate_An,t_Gate_Bp,t_Gate_Bn;
always @(posedge clk25MHz) begin
	  Gate_Ap<=pwm_drive[0]&delayed_driveA;
	  Gate_Bp<=pwm_drive[1]&delayed_driveB;
	  Gate_An<=~(pwm_drive[0]|delayed_driveA);
	  Gate_Bn<=~(pwm_drive[1]|delayed_driveB);
	  delay_lineA[k]<=pwm_drive[0];
	  delay_lineB[k]<=pwm_drive[1];
end

*/

//-------------------Phase Regualtion with Tunable Delay---------------------//

reg locked_temp=1'b0;
wire locked;  
assign locked=&{locked_temp,~shutdown,~alarm};
wire [8:0] abs_theta_f;
assign abs_theta_f=theta_f[8]? (~theta_f+1'b1):theta_f;
//always @(posedge standby) 	u<=u+1;
//always @(posedge clk600Hz) u<=theta_f[8]?(u-1):(u+1);
//always @(negedge clk600Hz) locked_temp<=~|abs_theta_f[8:4]; 
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
parameter shift=8'b00001000;
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
		    sum_VI<=(Vs^Is)? (sum_VI+1'b1):sum_VI;
			 sum_VI_d<=(Vs^Is_d)? (sum_VI_d+1'b1):(sum_VI_d-1'b1); end 
end
wire signed [8:0] theta_f;
LPF1d25kHz U8(.out(theta_f),.in(theta),.clk60kHz(pulse60kHz_d));


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

wire signed[8:0] theta_3deg;
assign theta_3deg=theta-3'd5;
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
	// lock frequency when frequency in lower then 55kHz or higher then 63kHz
	if(temp_accum_I>17'd73816&&temp_accum_I<17'd84557)
	begin
		accum_I <= temp_accum_I;  
	end
	else
	begin
		accum_I<= accum_I;
	end
end

reg [14:0] PI_control=start_point;
always@(negedge clk300Hz_pulse) 
begin
   // Round off two bits  
   PI_control<= temp_accum_I[16:2];
end

//-----PI contorl end-------//

reg signed [8:0] b1, b2, b3, b4, b5, b6, b7;
wire signed [11:0] sum_b;
assign sum_b={{3{b7[8]}},b7}+{{3{b6[8]}},b6}+{{3{b5[8]}},b5}+{{3{b4[8]}},b4}
           +{{3{b3[8]}},b3}+{{3{b2[8]}},b2}+{{3{b1[8]}},b1}+{{3{theta_f[8]}},theta_f};
reg signed [8:0] smooth_theta;

//always @(negedge clk600Hz) begin
always @(negedge clk2d5kHz) begin
	 b7<=b6;	 b6<=b5; b5<=b4;
	 b4<=b3; b3<=b2; b2<=b1; b1<=theta_f;
	 smooth_theta<=sum_b[11:3];  //2.5kHz/8=312.5 Hz
end	

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
assign status={locked,1'b0,low_impedance,high_impedance,no_locking};
LCD_display U9(.status(status),.freq(freq_display),.theta(theta_display),
            .power(power_display),.CLK(clk20MHz),.slowCLK(clk0d6Hz),.RESET(RST),
				.LCM_RW(RWW),.LCM_EN(E),.LCM_RS(RS),.LCM_DATA(D),.LCD_ON(ON));
				 
reg [8:0] theta_display;
reg [10:0] power_display;
reg [15:0] freq_display;
always @(posedge clk4Hz) begin
          freq_display<=shutdown? 16'b1110101001100000:freq_smooth[15:0];
			 //theta_display<=shutdown? 9'b0:delta_d;	//show delta
			 theta_display<=shutdown? 9'b0:smooth_theta;
			 //power_display<=shutdown? {1'b0,setpoint}:smooth_power;
			 power_display<=shutdown? 9'b0:smooth_power;
end
reg [10:0] a1, a2, a3, a4, a5, a6, a7;
wire [13:0] sum_a;
assign sum_a={{3{a7[10]}},a7}+{{3{a6[10]}},a6}+{{3{a5[10]}},a5}+{{3{a4[10]}},a4}
           +{{3{a3[10]}},a3}+{{3{a2[10]}},a2}+{{3{a1[10]}},a1}+{{3'b0},Io_sum[11:1]};
reg [10:0] smooth_power;

always @(negedge done_Io_count) begin
	 a7<=a6;	 a6<=a5; a5<=a4;
	 a4<=a3; a3<=a2; a2<=a1; a1<=Io_sum[11:1];
	 //smooth_power<=sum_a[13:3];
	 smooth_power<=sum_a[10:0];	//modify
end
		 
		 


//wire [9:0] test_bits;
//assign test_bits=10'b0110000000;
//wire [3:0] h, t, o;
//BCD U20(.hundreds(h),.tens(t),.ones(o),.in(test_bits));
//reg [6:0] LED;
//reg change=1'b0;
//always @(posedge clk0d3Hz) begin
//     change<=~change;
//     LED<=change?{h,t[3:2],1'b0}:{t[1:0],o,1'b0};
//end
	  //standby?power[23:17]:power[16:10];//{3'b0,power_level};//theta_f[7:1];//{theta_f[8],1'b0,u[4:0]};
wire test_p,test_n;
assign test_p=Vs;//locked_temp;//standby? Gate_Ap:Gate_Bp;//Iq;//u[8];//Vq;//standby? Gate_Ap1:Gate_Bp1;
assign test_n=Is;//standby? Gate_An:Gate_Bn;//Vq;//delayed_Iq;//u[7];//Iq;//standby? Gate_An1:Gate_Bn1;

endmodule

