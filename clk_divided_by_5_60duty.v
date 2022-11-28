module clk_divided_by_5_60duty(Out,In);
output Out;
input In;
reg [4:0] X;
assign Out=|X[4:2];
wire y;
assign y=~|X[3:0];
always @(posedge In) begin
    X[0] <= y;
	 X[4:1] <= X[3:0];
end
//always @(negedge In) begin
//    X[4]=X[3];
//end

endmodule  
