//------------- Increment-Controlled Oscillator (ICO) ------------//
//                                                                //
//         frequency = increment*(40e6)/(2^24)  Hz                //
//         [example] increment=15'b011001011001010 (13002)        //
//                   corresponds to 30.999kHz.                    //

module ICO(out,increment,clk40MHz);
output out;
input [14:0] increment;
input clk40MHz;

//--------------------------------------------------------------------//
// A counter counts up and down, 0<=count<=2^23; with an increment.   //
// The up and down correspond to the positive and negative cycles     //
// of the output 												                   //
//                           out=up_count                             // 

reg [23:0] count=24'b0;
reg up_count=1'b1; 

wire [23:0] delta,sum;
assign delta={9'b0,increment};	
assign sum=up_count?(count+delta):(count-delta);
//wire duty;
//assign duty=(~count[22]&~count[21]&~count[20])|(count[22]&count[21]&count[20])|(count[23]); // greater than 2^21=2097152(more precisely 1864110)
reg out;
always @(posedge clk40MHz) begin
    count 	<= sum[23]? ~(sum-{23'b0,1'b1})	:sum;
	 up_count<= sum[23]? ~up_count:up_count;
    //out<=duty^~up_count;
	 out<=up_count;
end

//wire out;
//assign out=up_count;


endmodule 