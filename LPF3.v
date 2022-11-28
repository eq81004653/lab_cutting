//--------------------- Lowpass Filter-------------------------//
//                z + 1                                        //
//              ---------  , fs, cutoff=1.25/60*fs kHz         //
//              16 z - 14                                      //

module LPF3(out,in,clk); 
input clk;
input signed [16:0] in;
output signed [16:0] out;
assign out=out16[20:4];
reg signed [20:0] out16;     				// out16 = 16*theta
reg signed [16:0] in_1;       				// in_1 = in(k-1)
wire signed [20:0] temp_sum;
assign temp_sum={{4{in[16]}},in}+{{4{in_1[16]}},in_1}+out16
                  -{{3{out16[20]}},out16[20:3]};
always @(posedge clk) begin
	 out16 <= temp_sum;
	 in_1 <= in;
end


endmodule
