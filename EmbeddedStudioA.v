// Top Level Module

module EmbeddedStudioA(clk,reset_n,scl,sda,character_selector,segment);

input clk,reset_n; //50MHz fpga clock, Reset, 
output scl;  //I2C clock, 250KHz
inout sda;   //I2C data
output[3:0] character_selector;  //7 segment display character selector
output[7:0] segment;  //7 segment display
wire[15:0] data; // Data

I2C I2C(
	.clk(clk), //50MHz fpga clock
	.reset_n(reset_n), // Reset
	.scl(scl), // Serial communications line
	.sda(sda), // Serial data line
	.data(data) // Data stream
);

SEGMENT_DISPLAY SEGMENT_DISPLAY(
	.clk(clk), //50MHz fpga clock
	.reset_n(reset_n), // Reset
	.segment(segment), // 7 segment display
	.data(data),	// Data
	.character_selector(character_selector)
);

endmodule
