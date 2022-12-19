module cutting_top(Gate_HI,Gate_LO,I,V,clk40MHz,T1,T2,Din,clk_out);

//output sd_clk;
input [4:0] Din;
output clk_out;
assign clk_out=clk40MHz;

output Gate_HI, Gate_LO;
output T1=Din[0];
output T2=Din[1];
input  I,V,clk40MHz;


//----------- Set the initial frequency SetPoint ------------------//
//parameter setPoint=15'd13002;

reg stop;
reg Sweep;


reg [14:0]setPoint; // 14700; freq = 35 kHz,13841=33k,14050=33.5k,14260=34k,14470=34.5k,14700=35k
always @(posedge clk40MHz)begin
//	setPoint<=(Din[4:0]<=5'd20)?(Din[4:0]<<7)+(Din[4:0]<<6)+(Din[4:0]<<4)+(Din[4:0]<<1)+15'd12582:setPoint;
//	setPoint<=(Din[4:0]<=5'd20)?({Din[4:0],8'd0}-{Din[4:0],5'd0})+15'd12460:setPoint;
//	Sweep<=(Din[4:0]==5'd23)?1'd1:(Din[4:0]==5'd24)?1'd0:Sweep;
//	stop<=(Din[4:0]==5'd22)?1'd0:(Din[4:0]==5'd21)?1'd1:stop;

	if(Din[4:0]<=5'd20)begin
		setPoint<=({Din[4:0],8'd0}-{Din[4:0],5'd0})+15'd12460;
//		setPoint<=setPoint;
		stop<=stop;
		Sweep<=Sweep;
	end
	else begin
		if(Din[4:0]==5'd21)begin
			setPoint<=setPoint;
			stop<=1'd0;
			Sweep<=Sweep;
		end

		else if(Din[4:0]==5'd22)begin
			setPoint<=setPoint;
			stop<=1'd1;
			Sweep<=Sweep;
		end

		else if(Din[4:0]==5'd23)begin
			setPoint<=setPoint;
			stop<=stop;
			Sweep<=1'd1;
		end

		else if(Din[4:0]==5'd24)begin
			setPoint<=setPoint;
			stop<=stop;
			Sweep<=1'd0;
		end

		else if(Din[4:0]==5'd25)begin
			setPoint<=15'd12460;
			stop<=1'd0;
			Sweep<=1'd1;
		end

		else begin
			setPoint<=setPoint;
			stop<=stop;
			Sweep<=Sweep;
		end
	end

end


//wire stop;	
//wire Sweep;
//output wire [14:0]setPoint;
//assign setPoint=(Din[4:0]<=5'd20)?({Din[4:0],8'd0}-{Din[4:0],5'd0})+15'd12460:setPoint;
//assign Sweep=(Din[4:0]==5'd23)?1'd1:(Din[4:0]==5'd24)?1'd0:Sweep;
//assign Sweep=1'd1;
//assign stop=(Din[4:0]==5'd22)?1'd0:(Din[4:0]==5'd21)?1'd1:stop;

//parameter setPoint=15'd14700; // 14700; freq = 35 kHz;
//13841=33k,14050=33.5k,14260=34k,14470=34.5k,14700=35k

//-------------- Increment-Controlled Oscillator (ICO) ------------//
//  The oscillation frequency varies with increment according to   //
//  frequency = increment*(40e6)/(2^24)  Hz                        //

//[14:0] increment;
wire Gate;
ICO U1(.out(Gate),.increment(increment),.clk40MHz(clk40MHz));

//----------------------------- Dead Time -------------------------//
//   Convert a switching command into 2 gate driving signals       //
//   with dead time equal to 1 us, 10 periods of a 10MHz clock.    //
//   high side of half-bridge: Gate_HI; low side: Gate_LO          //

//no deadtime need
assign Gate_HI=(stop)?1'd0:Gate;
assign Gate_LO=(stop)?1'd0:(!Gate);

reg [2:0] cnt;
wire clk5MHz,clk10MHz;
assign clk5MHz =cnt[2];
assign clk10MHz=cnt[1];
//reg Gate_LO,Gate_HI;

always @(negedge clk40MHz)  begin 
     cnt<=cnt+3'b001;
//	  Gate_HI<= Gate & delay_line[29];
//	  Gate_LO<= ~(Gate|delay_line[29]);	 
end 	

//reg [29:0] delay_line;
/*always @(posedge clk10MHz) begin
	  delay_line[29:0]<={delay_line[28:0],Gate};
end
*/

//--------------------- Phase detector ---------------------------// 
// 	    To detect abs_theta between V and I                     //
//        [Example]Given the driving frequency of 32 kHz          //
//        |theta|=5e6/32e3=156 corresponds to 180 degrees.        //

  // Generate a pulse at the positive edge of each cycle
  reg cycle_d1, cycle_d2, cycle_d3;
  always @(negedge clk5MHz) begin
	 cycle_d3 <= cycle_d2;
	 cycle_d2 <= cycle_d1;
	 cycle_d1 <= Gate;
  end
  wire pulse;
  assign pulse=cycle_d1&(~cycle_d2);

  // Count the number of NOR(I,V)=1 for each period of cycle
  wire XOR_IV;
  assign XOR_IV=I^~V;
  reg [7:0] accum=8'b0;
  wire [7:0] sum;
  assign sum = accum+XOR_IV;
  reg [7:0] abs_theta;
  always @(posedge clk5MHz) begin
     // When pulse=1, a new cycle begins
     if (pulse) begin
	        abs_theta <= sum; // Update the estimate
			  accum <=8'b0;     // Reset the accumulation
	  end else
	        accum <= sum;
  end

//--------350Hz-Cutoff Lowpass Filter (z+1)/(32z-30), fs=32kHz -------//
//           Remove noise from abs_theta to get theta                 //    
  wire [7:0] theta;
  //assign theta=abs_theta+{3'b000,Din};	//Din contorl lock deg
  assign theta=abs_theta;	//lock at zero
 // LPF2 U3(.out(theta),.in(abs_theta),.clk(cycle_d2));



//--------------------- Minimum Phase Seeking ------------------------//

  wire cycle500Hz;
  assign cycle500Hz=count[5];
  reg [5:0] count;
  always @(posedge cycle_d3) begin
      count<= count+6'b000001;
  end

  reg cycle500Hz_d1, cycle500Hz_d2;
  always @(posedge clk5MHz) begin
     cycle500Hz_d2 <= cycle500Hz_d1;
     cycle500Hz_d1 <= cycle500Hz;
  end
  wire pulse500Hz;  // pulse500Hz @ negedge cycle500Hz_d1
  assign pulse500Hz=(~cycle500Hz_d1)&cycle500Hz_d2; 

  reg [7:0] theta_past;
  always @(posedge cycle500Hz) begin     					
	    theta_past <= theta; 
  end

  // theta_past is the phase at lower frequency
  // theta      is the phase at higher frequency

  reg signed [8:0] delta;
  always @(negedge cycle500Hz) begin
        delta<= {1'b0,theta_past}-{1'b0,theta};
  end


  wire signed [16:0] temp_accum_I;
  assign temp_accum_I = accum_I + {{7{delta[8]}},delta,1'b0};

//  reg signed [16:0] accum_I={setPoint,2'b0};

	reg signed [16:0] accum_I;

//  reg signed [16:0] temp_accum_I=17'd58800;


//  wire chang_a;
//  assign chang_a=!Sweep;

//  always @(*) begin 
//		accum_I<=(chang)?{setPoint,2'b0}:accum_I;
//		PI_control<=(chang)?setPoint:PI_control;
//  end

//  reg chang_a;
  always @(posedge pulse500Hz) begin

//		chang_a<=(Sweep)?1'b0:1'b1;
     // PhaseNear90 = 1 when abs_theta > 64
//	  temp_accum_I <= {setPoint,2'b0} + {{7{delta[8]}},delta,1'b0};
     // accumulator for integration	  

//	  
	  if(Sweep==1'b1)
	    begin accum_I<={setPoint,2'b0};/*chang_a<=1'b0;chang_a<=1'b0;*/end
	  else
	    begin accum_I<=temp_accum_I;/*chang_a<=1'b1;chang_a<=1'b1;*/;end

//    accum_I<=temp_accum_I;
  end


  reg [14:0] PI_control=15'd13631;
  always @(negedge pulse500Hz) begin
      // Round off two bits  

		PI_control<=temp_accum_I[16:2];

//	  PI_control<=(chang_b)?setPoint:temp_accum_I[16:2];//temp_accum_I[1]? (temp_accum_I[16:2]+{14'b0,1'b1}):temp_accum_I[16:2];
  end

  // Perturb the freq by 2*38 Hz or 2*57 Hz (when PhaseNear90 = 1)
  wire [14:0] increment;
  //assign increment = PI_control+{9'b0,cycle500Hz_d2,cycle500Hz_d2&PhaseNear90,4'b0};
  assign increment=(Sweep)?setPoint:PI_control+{5'b0,cycle500Hz_d2,9'b0};
  //assign increment =setPoint;

endmodule