//---------------------1.25kHz Lowpass Filter------------------//
//                       z + 1                                 //
//                     ---------  , fs=60kHz                   //
//                     16 z - 14                               //

module LPF1d25kHz(out,in,clk60kHz); 
input clk60kHz;
input signed [8:0] in;
output signed [8:0] out;
assign out=out16[12:4];
reg signed [12:0] out16;     				// out16 = 16*theta
reg signed [8:0] in_1;       				// in_1 = in(k-1)
wire signed [12:0] temp_sum;
assign temp_sum={{4{in[8]}},in}+{{4{in_1[8]}},in_1}+out16
                  -{{3{out16[12]}},out16[12:3]};
always @(posedge clk60kHz) begin
	 out16 <= temp_sum;
	 in_1 <= in;
end


endmodule
