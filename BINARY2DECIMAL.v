module binary_decimal(reset, select, data, decimal, decimal_digit);

// Declare input and output signals and their widths
input reset; // Reset signal
input [7:0] data; // 8-bit input data
input [1:0] select; // 2-bit signal to select which digit to display
input decimal; // Single-bit input to decide if a decimal point should be displayed
output [3:0] decimal_digit; // 4-bit output for the decimal digit to be displayed

// Declare internal variables
reg [3:0] decimal_digit; // 4-bit register to hold the decimal digit
wire [6:0] whole_number; // 7-bit wire to hold the quotient of a division
wire [6:0] fraction; // 7-bit wire to hold the remainder of a division
reg [6:0] denom; // 7-bit register for the divisor

// Another 7-bit wire to hold the quotient of the second division
wire [6:0] whole_number_2;

/******************************************************************************
Set the denominator based on 'select' input for later division operations
To determine the value in the 10's and 1's segement based on the selector.
******************************************************************************/
always@ *
	begin
		if(!reset) // If reset is low, set the denominator to 1
			denom = 1; 
		else // If reset is not triggered
			case(select)
				2'b10: denom = 7'd10;	// For ones place
				2'b11: denom = 7'd100;	// For tens place
				default denom = 7'd1;	// Default value is 1
			endcase
	end

/******************************************************************************
These functions are division operations to find quotient and remainder.
******************************************************************************/
lpmdiv	lpmdiv_inst (
	.denom(denom), // Use the set denominator
	.numer (data), // Use the input data as the numerator
	.quotient (whole_number), // Store the quotient to whole_number
	.remain (fraction) // Store the remainder to fraction
);

lpmdiv lpmdiv_inst_2 (
	.denom(7'd10), // Set denominator to 10
	.numer (fraction), // Using the remainder from first division as the numerator
	.quotient (whole_number_2), // Store the to whole_number_2
	.remain () // Remainder of fraction is not used, it's just not
);

/******************************************************************************
This function selects and generates a digit to display.
******************************************************************************/
always@(whole_number, fraction, whole_number_2, decimal, reset)
	begin
		if(!reset) // resets back to 0 when reset is triggered
			decimal_digit = 0;
		else // If reset is not triggered
			case(select) // Update the display digit 
				2'b00: decimal_digit = 10; // Display special C haracter
				2'b01: decimal_digit = (decimal) ? 4'd5 : 4'd0; // Display either 5 or 0 as decimal
				2'b10: decimal_digit = fraction[3:0]; // Take the least significant 4 bits of the fraction
				2'b11: decimal_digit = whole_number_2[3:0]; // Take the 4 LSBs of whole_number_2
				default: decimal_digit = 0; // Default value is 0
			endcase
	end

endmodule