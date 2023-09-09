/******************************************************************************
This module handles the 7 Segment Display
******************************************************************************/
module SEGMENT_DISPLAY(clk,reset_n,segment,data,character_selector);
  
input clk; //50MHz fpga clock
input reset_n; // Reset
input [15:0]data; // Data stream
output [7:0] segment; // 7 segment display
output [3:0] character_selector; // 4 bit binary 

reg [7:0] segment;
reg [3:0] character_selector;
wire [4:0] dataout_buffer;
reg [1:0] display_data;
reg [16:0] delay_cnt;
reg [27:0]timer_cnt;
reg display;

/******************************************************************************
This function increments timer_cnt every 3 second.
******************************************************************************/	 
always@(posedge clk, negedge reset_n)  
    begin  
        if(!reset_n)
				// resets back to 0 when reset is triggered (negative edge)
				begin
					timer_cnt <= 28'd0;
					display <= 1'b0;
				end				
        else if(timer_cnt == 28'd149999997)  
				begin
					timer_cnt <= 28'd0;
					display <= display + 1'b1; // Increment the display when timer_cnt reaches its maximum		
				end
        else   
            timer_cnt <= timer_cnt + 1'b1;  
    end 

/******************************************************************************
This function calls the binary_decimal module.
******************************************************************************/
binary_decimal binary_decimal(
	.reset(reset_n),
	.select(display_data),
	.data(data[14:8]),
	.decimal(data[7]),
	.display_data(display),
	.decimal_digit(dataout_buffer)
);


/******************************************************************************
This function increments the delay count every 1 ms.
******************************************************************************/
always@(posedge clk,negedge reset_n)
	begin
		if(!reset_n)
			// resets back to 0 when reset is triggered (negative edge)
			delay_cnt<=16'd0;
		else if(delay_cnt==16'd50000)
			delay_cnt<=16'd0;  
		else   
			delay_cnt<=delay_cnt +1;  
	end
	
/******************************************************************************
This function increments which data to display every 1 ms.
******************************************************************************/
always@(posedge clk,negedge reset_n)  
	begin
		if(!reset_n) 
			// resets back to 0 when reset is triggered (negative edge)
			display_data<=2'd0;
		// Each clock cycle is 20ns (positive edge)
		// 20 ns * 50,000 = 1 ms
		else if(delay_cnt==16'd50000)
			// increments data_display binary value
			display_data<=display_data + 1'b1;  
		else
			display_data<=display_data;  
	end  

/******************************************************************************
This module selects which LED to display corresponding data using the
display_data variable.
******************************************************************************/	
always@(display_data)  
	begin  
		// Selects LED to display on
		// Low Active Setup
		case(display_data)
			// LEDs = |OFF|OFF|OFF|ON|
			2'b00: character_selector = 4'b1110;
			// LEDs = |OFF|OFF|ON|OFF|
			2'b01: character_selector = 4'b1101;
			// LEDs = |OFF|ON|OFF|OFF|
			2'b10: character_selector = 4'b1011;
			// LEDs = |ON|OFF|OFF|OFF|
			2'b11: character_selector = 4'b0111;
			default character_selector = 4'b1111; // All LED's off 
		endcase
	end

/******************************************************************************
This function takes the decimal digit (stored in dataout_buffer) and assigns
the relevant segment display.
******************************************************************************/
always@(dataout_buffer)
	begin 
		// Selects segment display based on decimal
		case(dataout_buffer)  
			4'd0 : segment = 8'hc0; //0
			4'd1 : segment = 8'hf9; //1
			4'd2 : segment = 8'ha4; //2
			4'd3 : segment = 8'hb0; //3
			4'd4 : segment = 8'h99; //4
			4'd5 : segment = 8'h92; //5
			4'd6 : segment = 8'h82; //6
			4'd7 : segment = 8'hf8; //7
			4'd8 : segment = 8'h80; //8
			4'd9 : segment = 8'h90; //9
			4'd10 : segment = 8'hc6; //C
			4'd11 : segment = 8'h89; //H
			4'd12 : segment = 8'hcF; //I
			default : segment =8'hFF; //NULL
		endcase
		// Add decimal point for second digit
		if((display_data == 2'b10) && (display == 0))
			segment = segment & 8'b01111111; 
	end

endmodule   