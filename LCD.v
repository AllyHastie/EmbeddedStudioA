module LCD(clk, data, rs, rw, en, dat);  

// Define inputs and outputs for the module and their sizes
input clk;  // Input clock signal
input [15:0] data; // 16-bit data input
output [7:0] dat; // 8-bit wide output data bus
output  rs,rw,en; // Control outputs: register select, read/write, and enable

// Internal signals
wire [11:0] bcd; // 12-bit BCD 


// Register declarations
reg e; // enable
reg [7:0] dat; // Data register with 8-bits
reg rs; // Register select
reg  [15:0] counter; // 16-bit counter
reg [4:0] current,next; // 5-bit registers for current and next state
reg clkr; // Clock register
reg [1:0] cnt; // 2-bit counter

/******************************************************************************
This function converts from binary to char using a lookup table.
******************************************************************************/
function [7:0] convert_to_char(input [3:0] input_data);
    case (input_data)
        4'b0000: convert_to_char = "0"; //0
        4'b0001: convert_to_char = "1"; //1
        4'b0010: convert_to_char = "2"; //2
        4'b0011: convert_to_char = "3"; //3
        4'b0100: convert_to_char = "4"; //4
        4'b0101: convert_to_char = "5"; //5
        4'b0110: convert_to_char = "6"; //6
        4'b0111: convert_to_char = "7"; //7
        4'b1000: convert_to_char = "8"; //8
        4'b1001: convert_to_char = "9"; //9
        default:   convert_to_char = " "; // Handle invalid values as needed
    endcase
endfunction

/******************************************************************************
This function calls the Binary_to_BCD module.
******************************************************************************/
Binary_to_BCD Binary_to_BCD (
	.bin(data[14:8]),
	.bcd(bcd)
);
// Parameter definitions for state machine
    parameter  set0=4'h0; 
    parameter  set1=4'h1; 
    parameter  set2=4'h2; 
    parameter  set3=4'h3; 
    parameter  dat0=4'h4; 
    parameter  dat1=4'h5; 
    parameter  dat2=4'h6; 
    parameter  dat3=4'h7; 
    parameter  dat4=4'h8; 
    parameter  dat5=4'h9; 
    parameter  dat6=4'hA; 
    parameter  dat7=4'hB; 
    parameter  dat8=4'hC; 
    parameter  dat9=4'hD; 
    parameter  dat10=4'hE; 
    parameter  dat11=5'h10; 
    parameter  dat12=5'h11; 
    parameter  dat13=5'h12; 
    parameter  dat14=5'h13; 
    parameter  dat15=5'h14;  
    parameter  nul=4'hF; 


/******************************************************************************
This function inverts clkr for LCD display
******************************************************************************/
always @(posedge clk)      
begin 
  counter=counter+1; // Increment counter by 1
  if(counter == 16'h000f)  // If counter reaches 15
	begin
		clkr=~clkr;  // Invert clkr
	end
end 


/******************************************************************************
This function displays the characters on the LCD screen.
******************************************************************************/
always @(posedge clkr) 
begin 
 current=next; // Move to the next state
  case(current) // For each state, set the rs, dat, and next state
    set0:   begin  rs<=0; dat<=8'h38; next<=set1; end // Command 0x38 makes display a 2 line 5 x 7 matrix
    set1:   begin  rs<=0; dat<=8'h0C; next<=set2; end // Command 0x0C turns the display on but the cursor off
    set2:   begin  rs<=0; dat<=8'h06; next<=set3; end // Command 0x06 increments the cursor (shifts cursor to the right)
    set3:   begin  rs<=0; dat<=8'h01; next<=dat0; end // Command 0x01 clears the display screen
    dat0:   begin  rs<=1; dat<="T"; next<=dat1; end //Displays "T"
    dat1:   begin  rs<=1; dat<="E"; next<=dat2; end //Displays "E"
    dat2:   begin  rs<=1; dat<="M"; next<=dat3; end //Displays "M"
    dat3:   begin  rs<=1; dat<="P"; next<=dat4; end //Displays "P"
    dat4:   begin  rs<=1; dat<=":"; next<=dat5; end //Displays ":"
    dat5:   begin  rs<=1; dat<=" "; next<=dat6; end //Displays " "
    dat6:   begin  rs<=1; dat<= convert_to_char(bcd[7:4]); next<=dat7; end //Displays largest temp BCD
    dat7:   begin  rs<=1; dat<= convert_to_char(bcd[3:0]); next<=dat8; end //Displays next temp BCD
    dat8:   begin  rs<=1; dat<= "."; next<=dat9; end //Displays decimal point
    dat9:   begin  rs<=1; dat<= convert_to_char((data[7]) ? 4'd5 : 4'd0); next<=dat10; end //Displays decimal.
	 // As a 9-bit register accuracy is only to 0.5 thus if bit is 1 it's .5 if bit is 0 it's 0
    dat10:  begin  rs<=1; dat<="C"; next<=dat11; end //Displays "C"
    dat11:  begin  rs<=1; dat<=" "; next<=dat12; end 
    dat12:  begin  rs<=1; dat<=" "; next<=dat13; end 
    dat13:  begin  rs<=1; dat<=" "; next<=dat14; end 
    dat14:  begin  rs<=1; dat<=" "; next<=dat15; end 	
    dat15:  begin  rs<=1; dat<=" "; next<=nul; end 
    nul:   begin rs<=0;  dat<=8'h00;                    
      if(cnt!=2'h2)  
        begin  
          e<=0;
          next<=set0;
          cnt<=cnt+1;  
        end  
      else 
		//resets LCD display
        begin 
          next<=nul; 
			 e<=1; 
			 cnt<=2'h0;
        end    
            end 
    default:   next=set0; 
  endcase 
end 

assign en = clkr | e; 
assign rw = 0; 

endmodule  