module clk_generator2(clk14MHz, clk100MHz, clk50MHz);
output clk14MHz, clk100MHz;
input clk50MHz;


// Generate clk 100MHz via PLL
wire locked;
wire clk100MHz;
PLL100MHz U1(.inclk0(clk50MHz), .c0(clk100MHz),.locked(locked));



wire clk14MHz,reset1;
reg [2:0] count1;
wire [2:0] sum1;
assign sum1=count1+1;
assign reset1=&sum1;
assign clk14MHz=count1[2];
always @(posedge clk100MHz) begin
      count1 <= reset1? 3'b0:sum1;
end

endmodule