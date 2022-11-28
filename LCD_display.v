//***********************************************//
//   Display on an LCD (4 rows x 16 characters)  //

module LCD_display(status,freq,theta,power,CLK,slowCLK,
           RESET, LCM_RW,LCM_EN, LCM_RS, LCM_DATA,LCD_ON);

  input [4:0] status;
  input [15:0] freq;
  input [8:0] theta;
  input [10:0] power;
  input  slowCLK,CLK;  //clk14MHz
  input  RESET;
  output LCM_EN;
  output LCM_RS;
  output [7:0]  LCM_DATA;
  output LCD_ON;
  output LCM_RW;
  
  reg    [7:0]  LCM_DATA; 
  reg    [5:0]  LCM_COUNT;
  reg	 [23:1] DIVIDER;
  reg    [7:0]  ROM_DATA0,ROM_DATA1,ROM_DATA2,ROM_DATA3;
  reg    [4:0]  ADDRESS0,ADDRESS1,ADDRESS2,ADDRESS3;
  reg    [4:0]  STATE;
  reg    [1:0]  ENABLE;
  wire   LCM_EN;
  reg    LCM_RS;
  //reg    LCM_RW;
  wire	 LCM_CLK;
  wire   LCD_ON;
  reg    LCM_RW;
  
  
  assign LCM_EN = ENABLE[0];
  assign LCD_ON=1;
 //--------------------BCD conversion for power------------------//
 wire [3:0] power_hundrens,power_tens,power_ones,power_f1, power_f2, power_f3;
 wire [9:0] power_integer, power_fraction;
 assign power_integer ={5'b0,power[10:6]};
 assign power_fraction={power[5:0],4'b0};
 BCD U11(.hundreds(power_hundrens),.tens(power_tens),.ones(power_ones),.in(power_integer));
 BCD U12(.hundreds(power_f1),.tens(power_f2),.ones(power_f3),.in(power_fraction));
 //--------------------BCD conversion for phase------------------//
 wire [3:0] theta_hundrens,theta_tens,theta_ones;
 wire [9:0] theta_integer;
 wire [8:0] theta_abs;
 assign theta_abs=theta[8]?(~theta+9'b000000001):theta;
 assign theta_integer ={1'b0,theta_abs};
 BCD U13(.hundreds(theta_hundrens),.tens(theta_tens),.ones(theta_ones),.in(theta_integer));
 //--------------------BCD conversion for freq------------------//
 wire [3:0] freq_ten_thous,freq_thousands,freq_hundrens,freq_tens,freq_ones;
 BCD2 U14(.ten_thous(freq_ten_thous),.thousands(freq_thousands),.hundreds(freq_hundrens),
      .tens(freq_tens),.ones(freq_ones),.in(freq));
  
 /************************
 * Timie Base Generator	*
 ************************/
  
  always @(negedge CLK)
    if (!RESET) 
      DIVIDER <= 15'o00000;
    else
	     DIVIDER <= DIVIDER + 1;
 
  assign LCM_CLK = DIVIDER[13];	// 14MHz/2^16= 218 Hz

//************************************//
//    Set the characters to display   //
  reg [127:0] row[3:0];
  initial begin
	  row[0]=" Ultrasonic Cut "; 
     row[1]="Cur  :  0.00   A";
	  row[2]="Freq : 60000  Hz";
	  row[3]="Phase:     0 deg";
	  
  end
 
  parameter p1=63;
  parameter p2=32;
  parameter p3=47;
  parameter p4=24;
  
  wire fault;
  assign fault=|status[2:0];
  always @(posedge CLK) begin
     if (status[3]) row[0]=slowCLK?"Fault:No Command":"Fault:          ";
     else if (fault) begin 
       case(status[2:0])
		   3'b100:row[0]=slowCLK?"Fault:  Short   ":"Fault:          ";
		   3'b010:row[0]=slowCLK?"Fault:  Open    ":"Fault:          ";
		   3'b001:row[0]=slowCLK?"Fault:No Locking":"Fault:          ";
			3'b011:row[0]=slowCLK?"Fault:No Locking":"Fault:          ";
			3'b101:row[0]=slowCLK?"Fault:No Locking":"Fault:          ";
		   default:row[0]="Fault           ";
		 endcase end
	  else if (status[4]) 
	             row[0]=slowCLK?"Frequency Locked":"                ";
	  else row[0]=" Ultrasonic Cut ";
  end	      
  reg CLK2,CLK3;
  always @(posedge CLK) CLK2<=~CLK2;
 // always @(posedge CLK2) CLK3<=~CLK3;
  
  always @(posedge CLK2) begin
     case(power_tens)
	     4'b0000:row[1][71:64]=" ";
		  4'b0001:row[1][71:64]="1";
		  4'b0010:row[1][71:64]="2";
		  4'b0011:row[1][71:64]="3";
		  4'b0100:row[1][71:64]="4";
		  4'b0101:row[1][71:64]="5";
		  4'b0110:row[1][71:64]="6";
		  4'b0111:row[1][71:64]="7";
		  4'b1000:row[1][71:64]="8";
		  4'b1001:row[1][71:64]="9";
		  default:row[1][71:64]=" ";
	  endcase
  end
  always @(posedge CLK2) begin
     case(power_ones)
	     4'b0000:row[1][63:56]="0";
		  4'b0001:row[1][63:56]="1";
		  4'b0010:row[1][63:56]="2";
		  4'b0011:row[1][63:56]="3";
		  4'b0100:row[1][63:56]="4";
		  4'b0101:row[1][63:56]="5";
		  4'b0110:row[1][63:56]="6";
		  4'b0111:row[1][63:56]="7";
		  4'b1000:row[1][63:56]="8";
		  4'b1001:row[1][63:56]="9";
		  default:row[1][63:56]=" ";
	  endcase
  end
  always @(posedge CLK2) begin
     case(power_f1)
	     4'b1001:row[1][47:40]="9";
	     4'b0000:row[1][47:40]="0";
		  4'b0001:row[1][47:40]="1";
		  4'b0010:row[1][47:40]="2";
		  4'b0011:row[1][47:40]="3";
		  4'b0100:row[1][47:40]="4";
		  4'b0101:row[1][47:40]="5";
		  4'b0110:row[1][47:40]="6";
		  4'b0111:row[1][47:40]="7";
		  4'b1000:row[1][47:40]="8";

		  default:row[1][47:40]=" ";
	  endcase
  end
  always @(posedge CLK2) begin
     case(power_f2)
	  	  4'b1001:row[1][39:32]="9";
	     4'b0000:row[1][39:32]="0";
		  4'b0001:row[1][39:32]="0";
		  4'b0010:row[1][39:32]="1";
		  4'b0011:row[1][39:32]="2";
		  4'b0100:row[1][39:32]="3";
		  4'b0101:row[1][39:32]="4";
		  4'b0110:row[1][39:32]="6";
		  4'b0111:row[1][39:32]="7";
		  4'b1000:row[1][39:32]="8";

		  default:row[1][39:32]=" ";
	  endcase
  end

    always @(posedge CLK) begin
     row[3][63:56]<=(&{|theta_hundrens,theta[8]})? "-":" ";
     case(theta_hundrens)
	     4'b0000:row[3][55:48]=(&{|theta_tens,theta[8]})?"-":" ";
		  4'b0001:row[3][55:48]="1";
		  4'b0010:row[3][55:48]="2";
		  4'b0011:row[3][55:48]="3";
		  4'b0100:row[3][55:48]="4";
		  4'b0101:row[3][55:48]="5";
		  4'b0110:row[3][55:48]="6";
		  4'b0111:row[3][55:48]="7";
		  4'b1000:row[3][55:48]="8";
		  4'b1001:row[3][55:48]="9";
		  default:row[3][55:48]=" ";
	  endcase
  end
  always @(posedge CLK) begin
     case(theta_tens)
	     4'b0000:row[3][47:40]=(|theta_hundrens)?"0":theta[8]?"-":" ";
		  4'b0001:row[3][47:40]="1";
		  4'b0010:row[3][47:40]="2";
		  4'b0011:row[3][47:40]="3";
		  4'b0100:row[3][47:40]="4";
		  4'b0101:row[3][47:40]="5";
		  4'b0110:row[3][47:40]="6";
		  4'b0111:row[3][47:40]="7";
		  4'b1000:row[3][47:40]="8";
		  4'b1001:row[3][47:40]="9";
		  default:row[3][47:40]=" ";
	  endcase
  end
  always @(posedge CLK) begin
     case(theta_ones)
	     4'b0000:row[3][39:32]="0";
		  4'b0001:row[3][39:32]="1";
		  4'b0010:row[3][39:32]="2";
		  4'b0011:row[3][39:32]="3";
		  4'b0100:row[3][39:32]="4";
		  4'b0101:row[3][39:32]="5";
		  4'b0110:row[3][39:32]="6";
		  4'b0111:row[3][39:32]="7";
		  4'b1000:row[3][39:32]="8";
		  4'b1001:row[3][39:32]="9";
		  default:row[3][39:32]=" ";
	  endcase
  end
  
  
  
    always @(posedge CLK) begin
     case(freq_ten_thous)
	     4'b0000:row[2][71:64]=" ";
		  4'b0001:row[2][71:64]="1";
		  4'b0010:row[2][71:64]="2";
		  4'b0011:row[2][71:64]="3";
		  4'b0100:row[2][71:64]="4";
		  4'b0101:row[2][71:64]="5";
		  4'b0110:row[2][71:64]="6";
		  4'b0111:row[2][71:64]="7";
		  4'b1000:row[2][71:64]="8";
		  4'b1001:row[2][71:64]="9";
		  default:row[2][71:64]=" ";
	  endcase
  end
  always @(posedge CLK) begin
     case(freq_thousands)
	     4'b0000:row[2][63:56]="0";
		  4'b0001:row[2][63:56]="1";
		  4'b0010:row[2][63:56]="2";
		  4'b0011:row[2][63:56]="3";
		  4'b0100:row[2][63:56]="4";
		  4'b0101:row[2][63:56]="5";
		  4'b0110:row[2][63:56]="6";
		  4'b0111:row[2][63:56]="7";
		  4'b1000:row[2][63:56]="8";
		  4'b1001:row[2][63:56]="9";
		  default:row[2][63:56]=" ";
	  endcase
  end
  
  
  always @(posedge CLK) begin
     case(freq_hundrens)
	     4'b0000:row[2][55:48]="0";
		  4'b0001:row[2][55:48]="1";
		  4'b0010:row[2][55:48]="2";
		  4'b0011:row[2][55:48]="3";
		  4'b0100:row[2][55:48]="4";
		  4'b0101:row[2][55:48]="5";
		  4'b0110:row[2][55:48]="6";
		  4'b0111:row[2][55:48]="7";
		  4'b1000:row[2][55:48]="8";
		  4'b1001:row[2][55:48]="9";
		  default:row[2][55:48]=" ";
	  endcase
  end
  always @(posedge CLK) begin
     case(freq_tens)
	     4'b0000:row[2][47:40]="0";
		  4'b0001:row[2][47:40]="1";
		  4'b0010:row[2][47:40]="2";
		  4'b0011:row[2][47:40]="3";
		  4'b0100:row[2][47:40]="4";
		  4'b0101:row[2][47:40]="5";
		  4'b0110:row[2][47:40]="6";
		  4'b0111:row[2][47:40]="7";
		  4'b1000:row[2][47:40]="8";
		  4'b1001:row[2][47:40]="9";
		  default:row[2][47:40]=" ";
	  endcase
  end
  always @(posedge CLK) begin
     case(freq_ones)
	     4'b0000:row[2][39:32]="0";
		  4'b0001:row[2][39:32]="1";
		  4'b0010:row[2][39:32]="2";
		  4'b0011:row[2][39:32]="3";
		  4'b0100:row[2][39:32]="4";
		  4'b0101:row[2][39:32]="5";
		  4'b0110:row[2][39:32]="6";
		  4'b0111:row[2][39:32]="7";
		  4'b1000:row[2][39:32]="8";
		  4'b1001:row[2][39:32]="9";
		  default:row[2][39:32]=" ";
	  endcase
  end


/*

  
		  
     case(sweep_range)
	     3'b001: row[0][p1:p2]="3~10";
		  3'b010: row[0][p1:p2]=" 3~7";
		  3'b011: row[0][p1:p2]=" 4~8";
	     3'b101: row[0][p1:p2]="10~3";
		  3'b110: row[0][p1:p2]=" 7~3";
		  3'b111: row[0][p1:p2]=" 8~4";
		  default:row[0][p1:p2]="3~10";
	  endcase
  end
  always @(posedge CLK) begin
     case(power)
	     2'b00:  row[1][p1:p2]=" 100";
	  	  2'b01:  row[1][p1:p2]=" 150";
		  2'b10:  row[1][p1:p2]=" 200";
	     2'b11:  row[1][p1:p2]=" 250";
		  default:row[1][p1:p2]=" 150";
	  endcase
  end
  always @(posedge CLK) begin
     case(ping_rate)
	     3'b001: row[2][p3:p4]="  5";
	  	  3'b010: row[2][p3:p4]="  2";
		  3'b011: row[2][p3:p4]="  1";
	     3'b100: row[2][p3:p4]="0.5";
		  3'b101: row[2][p3:p4]="0.2";
		  default:row[2][p3:p4]="  1";
	  endcase
  end	
  always @(posedge CLK) begin
     case(duration)
	    3'b001: row[3][p3:p4]=" 10";
	    3'b010: row[3][p3:p4]=" 20";
		 3'b011: row[3][p3:p4]=" 50";
	    3'b100: row[3][p3:p4]=" 70";
		 3'b101: row[3][p3:p4]="100";
		 3'b110: row[3][p3:p4]="200";
		 default:row[3][p3:p4]=" 50";
	  endcase
  end	
*/
  always @(ADDRESS0) begin
      case(ADDRESS0)
        4'h0   : ROM_DATA0 = row[0][127:120];
        4'h1   : ROM_DATA0 = row[0][119:112];
        4'h2   : ROM_DATA0 = row[0][111:104];
        4'h3   : ROM_DATA0 = row[0][103:96];
        4'h4   : ROM_DATA0 = row[0][95:88];
        4'h5   : ROM_DATA0 = row[0][87:80];
        4'h6   : ROM_DATA0 = row[0][79:72];
        4'h7   : ROM_DATA0 = row[0][71:64];
        4'h8   : ROM_DATA0 = row[0][63:56];
        4'h9   : ROM_DATA0 = row[0][55:48];
        4'hA   : ROM_DATA0 = row[0][47:40];
        4'hB   : ROM_DATA0 = row[0][39:32];
        4'hC   : ROM_DATA0 = row[0][31:24];
        4'hD   : ROM_DATA0 = row[0][23:16];
        4'hE   : ROM_DATA0 = row[0][15:8];
		  4'hF   : ROM_DATA0 = row[0][7:0];
      endcase
  end 
    
  always @(ADDRESS1) begin
      case(ADDRESS1)
        4'h0   : ROM_DATA1 = row[1][127:120];
        4'h1   : ROM_DATA1 = row[1][119:112];
        4'h2   : ROM_DATA1 = row[1][111:104];
        4'h3   : ROM_DATA1 = row[1][103:96];
        4'h4   : ROM_DATA1 = row[1][95:88];
        4'h5   : ROM_DATA1 = row[1][87:80];
        4'h6   : ROM_DATA1 = row[1][79:72];
        4'h7   : ROM_DATA1 = row[1][71:64];
        4'h8   : ROM_DATA1 = row[1][63:56];
        4'h9   : ROM_DATA1 = row[1][55:48];
        4'hA   : ROM_DATA1 = row[1][47:40];
        4'hB   : ROM_DATA1 = row[1][39:32];
        4'hC   : ROM_DATA1 = row[1][31:24];
        4'hD   : ROM_DATA1 = row[1][23:16];
        4'hE   : ROM_DATA1 = row[1][15:8];
		  4'hF   : ROM_DATA1 = row[1][7:0];
      endcase
  end 
  always @(ADDRESS2) begin
      case(ADDRESS2)
        4'h0   : ROM_DATA2 = row[2][127:120];
        4'h1   : ROM_DATA2 = row[2][119:112];
        4'h2   : ROM_DATA2 = row[2][111:104];
        4'h3   : ROM_DATA2 = row[2][103:96];
        4'h4   : ROM_DATA2 = row[2][95:88];
        4'h5   : ROM_DATA2 = row[2][87:80];
        4'h6   : ROM_DATA2 = row[2][79:72];
        4'h7   : ROM_DATA2 = row[2][71:64];
        4'h8   : ROM_DATA2 = row[2][63:56];
        4'h9   : ROM_DATA2 = row[2][55:48];
        4'hA   : ROM_DATA2 = row[2][47:40];
        4'hB   : ROM_DATA2 = row[2][39:32];
        4'hC   : ROM_DATA2 = row[2][31:24];
        4'hD   : ROM_DATA2 = row[2][23:16];
        4'hE   : ROM_DATA2 = row[2][15:8];
		  4'hF   : ROM_DATA2 = row[2][7:0];
      endcase
  end 
  always @(ADDRESS3) begin
      case(ADDRESS3)
        4'h0   : ROM_DATA3 = row[3][127:120];
        4'h1   : ROM_DATA3 = row[3][119:112];
        4'h2   : ROM_DATA3 = row[3][111:104];
        4'h3   : ROM_DATA3 = row[3][103:96];
        4'h4   : ROM_DATA3 = row[3][95:88];
        4'h5   : ROM_DATA3 = row[3][87:80];
        4'h6   : ROM_DATA3 = row[3][79:72];
        4'h7   : ROM_DATA3 = row[3][71:64];
        4'h8   : ROM_DATA3 = row[3][63:56];
        4'h9   : ROM_DATA3 = row[3][55:48];
        4'hA   : ROM_DATA3 = row[3][47:40];
        4'hB   : ROM_DATA3 = row[3][39:32];
        4'hC   : ROM_DATA3 = row[3][31:24];
        4'hD   : ROM_DATA3 = row[3][23:16];
        4'hE   : ROM_DATA3 = row[3][15:8];
		  4'hF   : ROM_DATA3 = row[3][7:0];
      endcase
  end 
     

/******************************
 * Initial And Write LCM Data *
 ******************************/

  always @(posedge LCM_CLK)   // 14MHz/2^16= 218 Hz
    begin
      if (!RESET)
		  	  	begin
          STATE    = 5'd0;   
          ENABLE  <= 2'b00;
          //LCM_RW  <= 1'b0;
          LCM_RS  <= 1'b0;
          LCM_DATA<= 8'h38;
			  	  end
      else
        if (ENABLE < 2'b10)      // count 0 1 2 0 1 2 0 1 2..., where at 1, E=1; at 0, data update. 
           ENABLE <= ENABLE + 1;  
        else if (STATE == 5'd0)  //idle 1
           begin
             STATE  = 5'd1;
             ENABLE<= 2'b00;
           end  
        else if (STATE == 5'd1)  //idle 2
            begin
              STATE  = 5'd21;
              ENABLE<= 2'b00;
            end
        else if (STATE == 5'd21) //idle 3
            begin
              STATE  = 5'd2;
              ENABLE<= 2'b00;
            end
        else if (STATE == 5'd2)  //idle 4
           begin
             STATE  = 5'd3;
             ENABLE<= 2'b00;
           end  
        else if (STATE == 5'd3)  //idle 5
           begin
             STATE  = 5'd4;
             ENABLE<= 2'b00;
           end  
        else if (STATE == 5'd4)  //idle 6
           begin
             STATE  = 5'd5;
             ENABLE<= 2'b00;
           end
        else if (STATE == 5'd5)  //idle 7, totally 7*3/218Hz=98 ms
           begin
             STATE  = 5'd6;     
             ENABLE<= 2'b00;
           end     
        
        else if (STATE == 5'd6) 
            begin
              STATE    = 5'd7;
              LCM_DATA<= 8'h38;  //configuration 1 (8 Bit,2 Lines)
              ENABLE  <= 2'b00;
            end
        else if (STATE == 5'd7) 
            begin
              STATE    = 5'd8;
              LCM_DATA<= 8'h38;  //configuration 2 (8 Bit,2 Lines)
              ENABLE  <= 2'b00;
            end
        else if (STATE == 5'd8) 
            begin
              STATE    = 5'd9;
              LCM_DATA<= 8'h38;  //configuration 3 (8 Bit,2 Lines)
              ENABLE  <= 2'b00;
            end         
        else if (STATE == 5'd9) 
            begin
              STATE    = 5'd10;
              LCM_DATA<= 8'h01;  //clear
              ENABLE  <= 2'b00;
            end  
        else if (STATE == 5'd10) 
            begin
              STATE    = 5'd11;
              LCM_DATA<= 8'h06;  //Entry mode, increase address by 1
              ENABLE  <= 2'b00;  
            end
        else if (STATE == 5'd11) 
           begin
             STATE    = 5'd12;
             LCM_DATA<= 8'h0C;   //Display on
             ENABLE  <= 2'b00; 
           end  
        else if (STATE == 5'd12) 
           begin
             STATE    <= 5'd13;
             LCM_RS   <= 1'b0;
             LCM_DATA<= 8'h80;  //Row no. 1;
             ENABLE  <= 2'b00; 
           end  
        else if (STATE == 5'd13) 
           begin  
             LCM_RS   <= 1'b1;   // Display on the 1st row
             if (ADDRESS0 < 15) begin
					 ADDRESS0 <= ADDRESS0 + 1;
					 ENABLE <= 2'b00; end 
             else begin
					 STATE	<=5'd14;
					 ENABLE <= 2'b00;
					 ADDRESS0  <= 4'h0;
				 end
			    LCM_DATA = ROM_DATA0;
           end
            
         else if (STATE == 5'd14) 
           begin
             STATE    <= 5'd15;
             LCM_RS   <= 1'b0;
             LCM_DATA <=8'hc0; //Row no. 2; 
             ENABLE  <= 2'b00;
           end
			else if (STATE == 5'd15) 
           begin  
             LCM_RS   <= 1'b1;   // Display on the 2nd row
             if (ADDRESS1 < 15) begin
					 ADDRESS1 <= ADDRESS1 + 1;
					 ENABLE <= 2'b00; end 
             else begin
					 STATE	<=5'd16;
					 ENABLE <= 2'b00;
					 ADDRESS1 <= 4'h0;
				 end
			    LCM_DATA = ROM_DATA1;
           end  
        else if (STATE == 5'd16) 
           begin
             STATE    <= 5'd17;
             LCM_RS   <= 1'b0;
             LCM_DATA<= 8'h90;   // Row no. 3; 
             ENABLE  <= 2'b00; 
           end  
		  
         else if (STATE == 5'd17) 
           begin  
             LCM_RS   <= 1'b1;    // Display on the 3rd row
             
             if (ADDRESS2 < 15) begin
                 ADDRESS2 <= ADDRESS2 + 1;
                 ENABLE <= 2'b00; end 
             else begin
					 STATE	<=5'd18;
					 ENABLE <= 2'b00;
					 ADDRESS2 = 4'h0;     
				 end
			    LCM_DATA = ROM_DATA2;
           end
		   else if (STATE == 5'd18) 
           begin
             STATE    <= 5'd19;
             LCM_RS   <= 1'b0;
             LCM_DATA<= 8'hd0;   // Row no. 4; 
             ENABLE  <= 2'b00; 
           end  
		  
         else if (STATE == 5'd19) 
           begin  
             LCM_RS   <= 1'b1;    // Display on the 4th row  
             if (ADDRESS3 < 15) begin
                 ADDRESS3 <= ADDRESS3 + 1;
                 ENABLE <= 2'b00; end 
             else begin
					 STATE	<=5'd12;
					 ENABLE <= 2'b00;
					 ADDRESS3 <= 4'h0;     
				 end
			    LCM_DATA = ROM_DATA3;
           end

        else if (STATE == 5'd20) 
           begin
             STATE    = 5'd21;
             LCM_RS   = 1'b0;
             LCM_DATA<= 8'b10000000; // Row no. 1
             ENABLE  <= 2'b00; 
           end  
        else if (STATE == 5'd21) 
           begin  
             LCM_RS   = 1'b1;  // Display on the 1st row
             
             if (ADDRESS0 < 15)
                begin
					ADDRESS0 <= ADDRESS0 + 1;
					ENABLE <= 2'b00;
                end
             else
				begin
					STATE	=5'd0;
					ENABLE <= 2'b00;
					ADDRESS0  = 4'h0;
				end
			 LCM_DATA = ROM_DATA0;
           end

    end
 
 
	
	 
	
endmodule	