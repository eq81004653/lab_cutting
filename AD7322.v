//---------------------------- ADC AD7322-------------------------------//
//    done=1 means convesion is done;												//
//    data & channel appear @posedge done											//
//    standby=0 means conversion of ch0 (voltage) & ch2  (current) 		//
//           =1 means conversion of ch1 (phase_adj) & ch3 (power_adj)	//
//    data = ch0 when channel= 2'b00 												//
//    data = ch1 when channel= 2'b01     											//    
//    data = ch2 when channel= 2'b10												//
//    data = ch3 when channel= 2'b11 												//
//    ch0 & ch1 data update at negedge of clk325kHz=channel[1]   			//
//    ch2 & ch3 data update at posedge of clk325kHz=channel[1]    		//

module AD7322(data, channel, done, CS ,SCLK ,DIN ,DOUT,clk20MHz);
output signed [12:0] data;
output channel;
output CS,SCLK,DIN,done;
input	 DOUT, clk20MHz;

//  count = 0, 1, 2,..., 19, 20, 0, 1, 2,...
//  Throughput rate = 20MHz/21 = 952.4 kHz
reg [4:0] count=5'd0; 
always @(posedge clk20MHz)
  begin
    if (count<21)
	    count <= count+1'b1;
	 else
	    count <= 1'b0;
  end

wire SCLK, dataReady, CS;
// dataReady= high when count = 2, 3, 4,..., 16, 17
assign dataReady=((count>1)&&(count<18))? 1'b1:1'b0;
// SCLK=clk20MHz (totally 16 pulses) when dataReady= high.
assign SCLK=(dataReady)?(clk20MHz & dataReady):1'b1; 
// CS= low when count = 2, 3, 4,..., 16, 17
assign CS=~dataReady;


//---------------- A Write to the Control Register in Each Cycle of Conversion --------------------//
//       Set the next channel for conversion: ch0 & ch2 when standby=0; ch1 & ch3 when standby=1   //
//       Other settings: single-ended inputs, normal power mode without power saving, 					//
//                       2's complement coding, internal reference, no sequencer operation. 			// 
//       Note: Default input range of +-10V, no setting of the range register is required.         //
//             -10V to 10V = -2048 to 2047 (totally 12 bits, in 2's complement coding)             //
wire start;
assign start=~|count; 	// start=1 when count=0 at the beginning of each 649kHz cycle
reg cnt;
always @(posedge start) begin
    cnt <= ~cnt;
end
reg [15:0]	configADC; 	
always @(negedge start) begin
// Flip {5'b10000,standby,10'b0000011100} from left to right;
// 16'b1000010000011100 ch1 (phase_set) when standby=1;16'b1000000000011100 ch0 (voltage) when standby=0;
// Flip {5'b10001,standby,10'b0000011100} from left to right;
// 16'b1000110000011100 ch3 (power_set) when standby=1;16'b1000100000011100 ch2 (current) when standby=0; 
	   configADC <= cnt? {10'b0011100000,1'b1,5'b00001}: {10'b0011100000,1'b0,5'b00001};
end
wire DIN;
assign DIN= dataReady? configADC[count-2'd2]:0;  //dataReady= high when count = 2, 3, 4,..., 16, 17 

 
//-------------------- Read in Data ------------------------//
// DOUT=[zerobit ch_id1 ch_id0 sign D11 D10 .... D2 D1 D0]		
 reg 	[15:0] shiftData;
 always @(negedge SCLK)
   begin
			shiftData <= {shiftData[14:0],DOUT};
	end

reg state1=0;
//reg state2=0;
wire ch0_e=state1;//done;//^shiftData[14];
wire ch2_e=~state1;

// done=1 when count=20, indicating that the data conversion is complete.
wire done;
assign done = (count==20);
reg signed	[12:0] data=13'b0;
reg channel;
always @(posedge done)
   begin  
      channel <= shiftData[13];   //shiftData[14]=0 for 2-channel ADC AD7322
	   data    <= shiftData[12:0];	
	end
endmodule