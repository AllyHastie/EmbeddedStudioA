module binary_decimal(reset, select, data, decimal, decimal_digit);

input reset; // Reset
input [7:0] data; //
input [1:0] select; //Segement Display
input decimal;
output [3:0] decimal_digit;

reg [3:0] decimal_digit;
wire [6:0] whole_number;
wire [6:0] fraction;
reg [6:0] denom;

wire [6:0] whole_number_2;

/******************************************************************************
This function sets the denominator for division to determine the value
in the 10's and 1's segement based on the selector.
******************************************************************************/
always@ *
	begin
		if(!reset)
			denom = 1; 
		else
			case(select)
				2'b10: denom = 7'd10; // ones
				2'b11: denom = 7'd100; // tens
				default denom = 7'd1;
			endcase
	end

/******************************************************************************
These functions are division operations.
******************************************************************************/
lpmdiv	lpmdiv_inst (
	.denom(denom),
	.numer (data),
	.quotient (whole_number),
	.remain (fraction)
);

lpmdiv lpmdiv_inst_2 (
	.denom(7'd10),
	.numer (fraction),
	.quotient (whole_number_2),
	.remain ()
);

/******************************************************************************
This function selects and generates a digit to display.
******************************************************************************/
always@(whole_number, fraction, whole_number_2, decimal, reset)
	begin
		if(!reset)
			// resets back to 0 when reset is triggered
			decimal_digit = 0;
		else
			case(select)
				2'b00: decimal_digit = 10;
				2'b01: decimal_digit = (decimal) ? 4'd5 : 4'd0; 
				2'b10: decimal_digit = fraction[3:0];
				2'b11: decimal_digit = whole_number_2[3:0];
				default decimal_digit = 0;
			endcase
	end

endmodule