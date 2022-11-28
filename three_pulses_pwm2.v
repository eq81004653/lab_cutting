  //-------Three-Pulse PWM in synchrony with switching command cycle------//
//       its modulation index determined by 8-bit input in.             //
//                                                                      //
//         frequency = increment*(100e6)/(2^27*4)  Hz                   //
//         [example] increment='011010001101110000' (6711*16)           //
//                   corresponds to 20kHz.                              //
//                                                                      //
//   Input: cycle=1 positive cycle; cycle=0 negative cycle              //
//   Reset count & down to zero at posedge & negedge of cycle           //
//                                                                      //
//   Input         in: 180  160  140  120  100   80   60   40   20  0   //
//   modulation index: 0.1  0.2  0.3  0.4  0.5  0.6  0.7  0.8  0.9  1   //

 
module three_pulses_pwm2(pwm_drive,in,cycle,clk100MHz);
output [1:0] pwm_drive;
input [7:0] in;
input cycle,clk100MHz;
//---------------Count the half period of cycle---------------------------//
wire edges;
assign edges=cycle_d2^cycle_d;
reg cycle_d, cycle_d2;//, cycle_d3, cycle_d4, cycle_d5, cycle_d6;
//wire count_N_ok, calculate_increment_ok;
//assign count_N_ok=cycle_d2^cycle_d;
//assign calculate_increment_ok=cycle_d5^cycle_d6;
always @(negedge clk100MHz) begin
//  cycle_d6<=cycle_d5;
//  cycle_d5<=cycle_d4;
//  cycle_d4<=cycle_d3;
//  cycle_d3<=cycle_d2;
  cycle_d2<=cycle_d;
  cycle_d <=cycle;
end
/*
wire [12:0] sum_temp;
assign sum_temp=count_half_period+1;
reg [12:0] count_half_period=13'b0;
reg [12:0] N;
always @(posedge clk100MHz) begin
     if (count_N_ok) begin
	     N<=sum_temp;
		  count_half_period<=13'b0; end
	  else
	     count_half_period<=sum_temp;
end 


wire [28:0] num;
assign num={1'b1,28'b0};
wire [28:0] increment;
divide_by_N U1(.clock(calculate_increment_ok),.denom(N),.numer(num),
	            .quotient(increment),.remain());
  */  

//-------------------------------------------------------------------------//
// A counter counts up and down, 0<=count<=2^27; with an increment         //
// to create a triangular wave. two triangles form a period, one           //
// for positive cycle (cycle=1) & the other for negative scycle (cycle=0). //
// triangle=count/2^13 swings between 0 and 2^14.                          // 

wire [14:0] triangle;
assign triangle=count[27:13]; 
reg [27:0] count=28'b0;
reg down=1'b0; 
// Set delta equal to (desired frequency in Hz)*(2^29)/(100e6)
wire [27:0] delta;
assign delta={9'b0,19'b1001110101001010000}; // default=60kHz
//assign delta={10'b0,18'b011010001101110000}; // default=20kHz
//assign delta={10'b0,increment1};	
wire [27:0] count_minus_delta, count_plus_delta;
assign count_minus_delta=count-delta;
assign count_plus_delta=count+delta;
reg [27:0] sum;

always @(negedge clk100MHz) begin
  sum <= down? count_minus_delta : count_plus_delta;
end
// sum[27]=1 when counting to 2^27 or to negative
wire [27:0] count_temp;
assign count_temp=sum[27]? ~(sum-1'b1):sum;

reg [17:0] increment1;
always @(posedge clk100MHz) begin
    if (edges==1) begin  // reset the count at both edges // and increment update
	    count <=28'b0;
		 down <=1'b0; end
		// increment1<=increment[17:0]; end 
	 else begin
       count <= count_temp;
	    down <= sum[27]? 1'b1: down;
	 end
end

reg signed [14:0] diff1,diff2, diff3;
always @(negedge clk100MHz) begin
   diff1<=xx1-triangle;
   diff2<=triangle-xx2;
   diff3<=xx3-triangle;
end

//---------------------- Three-Pulse PWM -----------------------//
//    The modulation index determined by input 0<=in<=200       //
//    The lower in, the higher the modulation index.            //

parameter word_length=8, table_size=201;
reg [word_length-1:0] x2[table_size-1:0];
reg [word_length-1:0] x3[table_size-1:0];
initial $readmemb("X2.txt",x2,0,table_size-1);
initial $readmemb("X3.txt",x3,0,table_size-1);

wire [14:0] xx1, xx2, xx3;
assign xx1={1'b0,in,6'b0}+16'b001001011010000;		//xx1=2*in+602; 		// 602= '001001011010'
assign xx2={4'b0100,x2[in],3'b0};   					//xx2=x2[in]+1024;	// {3'b0,x2[in]}+1024;
assign xx3={2'b01,x3[in],5'b10000};  					//xx3=4*x3[in]+1026; // {1'b0,x3[in],2'b0}+1026;

reg [1:0] S;  // S[0]=1 generates a pulse, S[0]=0 no pulse. S[1] indicates positive or negative pulse.
always @(posedge clk100MHz)  begin     
	 //S[0]<= diff3[14]|(diff1[14] & diff2[14]);//(triangle>xx3)||((xx2>triangle)&&(triangle>xx1));// //
	 S[0]<= diff1[14];//modify
	 S[1]<= cycle_d;  
end
assign pwm_drive[0]=&S;        // out = 10  positive pulse; 00 no pulse; 01 negative pulse
assign pwm_drive[1]=(~S[1])&S[0];



endmodule 