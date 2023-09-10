// Top Level Module
module EmbeddedStudioA(clk,reset_n,scl,sda,character_selector,segment);

// Define inputs and outputs for the module
input clk,reset_n;               // Declare clk and reset_n as input signals. clk is the 50MHz clock for the FPGA and reset_n is the reset signal.
output scl;                      // Declare scl as an output. This is the I2C clock running at 250KHz.
inout sda;                       // Declare sda as an inout. This is the I2C data line.
output[3:0] character_selector;  // Declare a 4-bit output for the 7-segment display character selector.
output[7:0] segment;             // Declare an 8-bit output for the 7-segment display itself.

// Internal signals
wire[15:0] data;                 // Declare a 16-bit wire called 'data' for internal data communication.

// Instantiate the I2C module
I2C I2C(
	.clk(clk),                  // Connect the 50MHz FPGA clock to the clk input of the I2C module
	.reset_n(reset_n),          // Reset signal to the reset_n input
	.scl(scl),                  // I2C clock signal to the scl input
	.sda(sda),                  // I2C data signal to the sda input/output 
	.data(data)                 // 16-bit internal data wire to the data input/output 
);

// Instantiate the SEGMENT_DISPLAY module
SEGMENT_DISPLAY SEGMENT_DISPLAY(
	.clk(clk),                  // Connect the 50MHz FPGA clock to the clk input of the SEGMENT_DISPLAY module
	.reset_n(reset_n),          // Reset signal to the reset_n input
	.segment(segment),          // 8-bit output to the segment output 
	.data(data),                // 16-bit internal data wire to the data input 
	.character_selector(character_selector) // 4-bit output to the character_selector output
);

endmodule
