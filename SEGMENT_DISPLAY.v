/******************************************************************************
This module handles the 7 Segment Display
******************************************************************************/
module SEGMENT_DISPLAY(clk,reset_n,segment,data,character_selector);

input clk;                          // Input signal for 50MHz clock
input reset_n;                      // Input signal for reset (active low)
input [15:0] data;                  // 16-bit wide input data stream
output [7:0] segment;               // 8-bit wide output for 7-segment display
output [3:0] character_selector;    // 4-bit wide output to select which character to display

reg [7:0] segment;                  // Declare 8-bit wide register to hold data for 7-segment display
reg [3:0] character_selector;       // Declare 4-bit wide register to hold data for character selection
wire [4:0] dataout_buffer;          // 5-bit wire to hold intermediate data
reg [1:0] display_data;             // 2-bit wide register to hold processed display data
reg [16:0] delay_cnt;               // 17-bit wide register to hold delay counter value

/******************************************************************************
This function calls the binary_decimal module.
******************************************************************************/
binary_decimal binary_decimal( 
	.reset(reset_n),             // Input: reset signal (usually to initialize or clear)
	.select(display_data),       // Input: data selection signal (controls what to display)
	.data(data[14:8]),           // Input: a subset of 'data', taking bits from 14 to 8
	.decimal(data[7]),           // Input: the 7th bit of 'data' as the decimal value
	.decimal_digit(dataout_buffer) // Output: buffer where the computed decimal digit will be stored
);

/******************************************************************************
This function increments the delay count every 1 ms.
Triggered on the rising edge of 'clk' or the falling edge of 'reset_n'.
******************************************************************************/
always@(posedge clk,negedge reset_n)
	begin
		// If reset signal is low (! means NOT, so !reset_n means reset_n is 0)
		if(!reset_n) // resets back to 0 when reset is triggered (negative edge)
			delay_cnt<=16'd0; // resets back to 0 when reset is triggered (negative edge)
		else if(delay_cnt==16'd50000) // If delay counter reaches 1 ms delay
			delay_cnt<=16'd0;  // resets back to 0 when delay_cnt reaches 1 ms
		else // If delay counter is not yet 1 ms
			delay_cnt<=delay_cnt +1; // increments delay_cnt every clock cycle
	end
	
/******************************************************************************
This function increments which data to display every 1 ms.
Triggered on the rising edge of 'clk' or the falling edge of 'reset_n'.
******************************************************************************/
always@(posedge clk,negedge reset_n)  
	begin
		if(!reset_n) // resets back to 0 when reset is triggered (negative edge)
			display_data<=2'd0; 
		// Each clock cycle is 20ns (positive edge)
		// 20 ns * 50,000 = 1 ms
		else if(delay_cnt==16'd50000) // If delay counter reaches 1 ms delay
			display_data<=display_data + 1'b1; // increments data_display binary value
		else // if neither reset condition nor delay condition is met
			display_data<=display_data; // data_display remains the same
	end  

/******************************************************************************
This module selects which LED to display corresponding data using the
display_data variable.
Executes whenever there's a change in the 'display_data' signal
******************************************************************************/	
always@(display_data)  
	begin  
		// Selects LED to display on
		// Low Active Setup
		case(display_data)
			// If 'display_data' is 2'b00, set 'character_selector' to 4'b1110
			// Meaning: Turn on the fourth LED and turn off the rest
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
Triggered whenever 'dataout_buffer' changes
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
			4'd10 : segment = 8'hc6; //C, but a very very very hot C
			default : segment =8'hc0; // For any other value, just display 0
		endcase
		// Add decimal point for second digit
		if(display_data == 2'b10) // If 'display_data' is 2'b10
			segment = segment & 8'b01111111; // Add decimal point to the 'segment'
	end

endmodule   
