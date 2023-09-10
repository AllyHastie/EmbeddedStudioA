module I2C(
	clk,        // Clock input
	reset_n,    // Reset signal (Active low)
	scl,        // Clock signal for I2C
    sda,        // Clock signal for I2C
    data        // 16-bit data to be transmitted
);

// Declaring inputs and outputs
input clk;          //50MHz fpga clock
input reset_n;      // Active-low reset signal
output scl;         // Clock output for I2C
inout  sda;         // Bidirectional data line for I2C
output [15:0] data; // 16 bit of data received across 2 x 8 bit data frames

// Declaring internal registers
reg [15:0]data_register;    // Register to hold 16-bit data
reg scl;                    // Register to hold SCL (I2C clock) state
reg sda_register;           // Register to hold SDA (I2C data) state
reg sda_link;               // Register to link SDA state
reg [7:0]scl_cnt;           // Counter for SCL clock
reg [2:0]cnt;               // General counter
reg [25:0]timer_cnt;        // Timer counter
reg [3:0]data_cnt;          // Counter for data bits
reg [7:0]address_register;  // Register to hold the device address
reg [8:0]state;             // Register to hold the state machine state

/******************************************************************************
This function increments the scl count every 5 us.
******************************************************************************/
always@(posedge clk or negedge reset_n)  
    begin  
        if(!reset_n) // If reset is low
            scl_cnt <= 8'd0; // resets back to 0 when reset is triggered (negative edge)
        else if(scl_cnt == 8'd199) //counts 5 us
            scl_cnt <= 8'd0;  // Reset the counter when it reaches 199
        else  // Otherwise increment the counter by 1
            scl_cnt <= scl_cnt + 1'b1;  // Increment the SCL counter
    end  

/******************************************************************************
This function implements a state machine based on SCL_CNT.
******************************************************************************/
always@(posedge clk or negedge reset_n)  
    begin  
        if(!reset_n) // If reset is low
            cnt <= 3'd5; // resets counter to state 5 when triggered (negative edge)
        else // otherwise increment counter based on SCL_CNT value
            case(scl_cnt)
				8'd49: cnt  <= 3'd1; // When scl_cnt reaches 49, set cnt to 1
				8'd99: cnt  <= 3'd2; // When scl_cnt reaches 99, set cnt to 2
				8'd149: cnt <= 3'd3; // When scl_cnt reaches 149, set cnt to 3
				8'd199: cnt <= 3'd0; // When scl_cnt reaches 199, set cnt to 0
               default: cnt <= 3'd5; // Otherwise, keep cnt to 5
            endcase  
    end 

// Define macros for SCL states
`define SCL_HIG (cnt == 3'd1)  // SCL high condition
`define SCL_NEG (cnt == 3'd2)  // SCL negative edge condition
`define SCL_LOW (cnt == 3'd3)  // SCL low condition
`define SCL_POS (cnt == 3'd0)  // SCL positive edge condition

// Update scl signal based on cnt value
always@(posedge clk or negedge reset_n) // SCL signal
    begin  
        if(!reset_n) // If reset is low
            scl <= 1'b0; // Set scl low
        else if(`SCL_POS) // If positive edge condition for SCL
            scl <= 1'b1; // Set scl high
        else if(`SCL_NEG) // If negative edge condition for SCL
            scl <= 1'b0; // Set scl low
    end  

/******************************************************************************
This function increments timer_cnt every 1 second.
******************************************************************************/	 
always@(posedge clk or negedge reset_n)  // 1 second timer counter 
    begin  
        if(!reset_n) // If reset is low
            timer_cnt <= 26'd0; // resets timer_cnt back to 0 when reset is triggered (negative edge) 
        else if(timer_cnt == 26'd49999999) //counts 1 second
            timer_cnt <= 26'd0; // If timer_cnt is 1s, it is reset back to 0
        else // Otherwise increment the counter by 1  
            timer_cnt <= timer_cnt + 1'b1; // Increments timer_cnt by 1
    end  

// I2C States
parameter IDLE  = 9'b0_0000_0000, // I2C Idle State indicates that the line is not busy
             START      = 9'b0_0000_0010, // Start I2C transmission
             ADDRESS    = 9'b0_0000_0100, // Transmission of Addresss 
             ACK1       = 9'b0_0000_1000, // Acknowledgement bit 1
             READ1      = 9'b0_0001_0000, // Read data frame 1 (8 bits)
             ACK2       = 9'b0_0010_0000, // Acknowledgement bit 2
             READ2      = 9'b0_0100_0000, // Read data frame 2 (8 bits) 
             NACK       = 9'b0_1000_0000, // No Acknowledge bit
             STOP       = 9'b1_0000_0000; // Stop I2C transmission
`define DEVICE_ADDRESS 8'b1001_0001 // LM75 Slave Address 0x91

/******************************************************************************
This function uses I2C communication to transmit 16 bits of data from 
peripherals.
******************************************************************************/  
always@(posedge clk or negedge reset_n)  
    begin  
        if(!reset_n) //if the reset_n signal is low
			// Initialise state to IDLE to indicate I2C line is not busy
            begin  
                data_register       <= 16'd0;   // Reset the data_register to 0
                sda_register        <= 1'b1;    // Set the SDA (Serial Data) line to high
                sda_link            <= 1'b1;    // Also set the sda_link to high
                state               <= IDLE;    // Set the state to IDLE
                address_register    <= 8'd0;    // Reset the address_register to 0
                data_cnt            <= 4'd0;    // Reset the address_register to 0
            end  
        else // If reset_n is high
            case(state) 
					// I2C Idle State indicates that the line is not busy
					IDLE:  
                    begin
                        sda_register    <= 1'b1; // Set SDA to high
                        sda_link        <= 1'b1; // Also set the sda_link to high
                        if(timer_cnt == 26'd49999999)  // After 1 second change state to START
                            state <= START; // Transition to the START state
                        else  
                            state <= IDLE; // Stay in the IDLE state
                    end  
                    // I2C start condition occurs when SCL is high and SDA changes from High to Low
					START:
                    begin
                        if(`SCL_HIG)  
                            begin 
                                sda_register <= 1'b0; // Set SDA to low
                                sda_link     <= 1'b1; // Set sda_link to high
                                address_register <= `DEVICE_ADDRESS; // Store the slave device address in the address register
								// When SDA is set low I2C transmission starts. Change to next state, transmitting the sensor address
                                state           <= ADDRESS; // Transition to ADDRESS state
                                data_cnt        <= 4'd0;    // Reset the data count
                            end  
                        else  
                            state <= START; // Stay in the START state if SCL is not high
            end
                    end

				// I2C Address transmission occurs after start condition is set
                ADDRESS:
                    begin  
                        if(`SCL_LOW)
                            begin  
                                if(data_cnt == 4'd8)  // If 8 bits have been transmitted
                                    begin  
                                        state           <= ACK1; // Change state to ACK1 for Acknowledgment bit 1
                                        data_cnt        <= 4'd0; // Reset the data count 
                                        sda_register    <= 1'b1; // Set SDA to high
                                        sda_link        <= 1'b0; // Set sda_link to low
                                    end  
                                else
                                    begin  
                                        state    <= ADDRESS;  // Stay in the ADDRESS state
                                        data_cnt <= data_cnt + 1'b1; // Increment the data count
										// Transfer slave address to SDA register 
                                        case(data_cnt)
                                            // Transfer the MSB of the address to the SDA register
                                            4'd0: sda_register <= address_register[7]; 
                                            4'd1: sda_register <= address_register[6]; 
                                            4'd2: sda_register <= address_register[5];
                                            4'd3: sda_register <= address_register[4];
                                            4'd4: sda_register <= address_register[3];
                                            4'd5: sda_register <= address_register[2];
                                            4'd6: sda_register <= address_register[1];
                                            4'd7: sda_register <= address_register[0];
                                            default: ;  // Do nothing
                                        endcase  
                                    end  
                            end  
                        else  // If SCL is not low
                            state <= ADDRESS; // Stay in the ADDRESS state
                    end 

				// Acknowlegdment bit 1
                ACK1:
                    begin  
                        if(!sda && (`SCL_HIG)) // If SDA is low and SCL is high
                            state <= READ1;  
                        else if(`SCL_NEG)  // If SCL is low and SDA is high
                            state <= READ1;  
                        else  // otherwise stay in ACK1 state
                            state <= ACK1; 
                    end  

				// Read data frame 1 (8 bits)
                READ1:
                    begin 
						// If 8 bits have been read and SCL is low change state to acknowledge data frame
                        if((`SCL_LOW) && (data_cnt == 4'd8))
								begin  
                                state           <= ACK2; // Change state to ACK2 for Acknowledgment bit 2
                                data_cnt        <= 4'd0; // Reset the data count
                                sda_register    <= 1'b1; // Set SDA to high
                                sda_link        <= 1'b1; // Set sda_link to high
                            end  
						// If SCL is high store SDA state in register
                        else if(`SCL_HIG)  
                            begin  
                                data_cnt <= data_cnt + 1'b1; // Increment the data count 
                                case(data_cnt)  
                                    4'd0: data_register[15] <= sda;  
                                    4'd1: data_register[14] <= sda;  
                                    4'd2: data_register[13] <= sda;  
                                    4'd3: data_register[12] <= sda;  
                                    4'd4: data_register[11] <= sda;  
                                    4'd5: data_register[10] <= sda;  
                                    4'd6: data_register[9]  <= sda;  
                                    4'd7: data_register[8]  <= sda;  
                                    default: ;  // Do nothing
                                endcase  
                            end  
                        else  
                            state <= READ1;  
                    end

				// Acknowlegdment bit 2  
                ACK2:  
                    begin     
                        if(`SCL_LOW)  // If SCL is low and SDA is low
                            sda_register <= 1'b0; // Set SDA to low 
                        else if(`SCL_NEG) // If SCL is low and SDA is high 
                            begin  
                                sda_register    <= 1'b1; // Set SDA to high
                                sda_link        <= 1'b0; // Set sda_link to low
                                state           <= READ2;  
                            end  
                        else  
                            state <= ACK2;  
                    end 

				// Read data frame 2 (8 bits)
                READ2: 
                    begin  
						// If 8 bits have been read and SCL is low change state for no acknowledgment
                        if((`SCL_LOW) && (data_cnt == 4'd8))
                            begin  
                                State           <= NACK;  // Change state to NACK for No Acknowledgment bit
                                data_cnt        <= 4'd0;  // Reset the data count
                                sda_register    <= 1'b1;  // Set SDA to high
                                sda_link        <= 1'b1;  // Set sda_link to high
                            end  
						// If SCL is high store SDA state in register
                        else if(`SCL_HIG)  
                            begin  
                                data_cnt <= data_cnt + 1'b1;  // Increment the data count
                                case(data_cnt)  
                                    4'd0: data_register[7] <= sda;  
                                    4'd1: data_register[6] <= sda;  
                                    4'd2: data_register[5] <= sda;  
                                    4'd3: data_register[4] <= sda;  
                                    4'd4: data_register[3] <= sda;  
                                    4'd5: data_register[2] <= sda;  
                                    4'd6: data_register[1] <= sda;  
                                    4'd7: data_register[0] <= sda;  
                                    default: ;  
                                endcase  
                            end  
                        else  
                            state <= READ2;  
                    end

				// No Acknowlegdment bit  
                NACK:
                    begin  
                        if(`SCL_LOW)  
                            begin  
                                state           <= STOP; // Change state to STOP for stop condition
                                sda_register    <= 1'b0;  // Set SDA to low 
                            end  
                        else  
                            state <= NACK; // Stay in the NACK state
                    end 

				// I2C stop condition occurs when SCL is high and SDA changes from Low to High
                STOP:  
                    begin  
                        if(`SCL_HIG)  
                            begin  
                                state           <= IDLE;  // Change state to IDLE
                                sda_register    <= 1'b1;  // Set SDA to high
                            end  
                        else  
                            state <= STOP;  // Stay in the STOP state
                    end  
                default: state <= IDLE;  // If no state is selected, set the state to IDLE
            endcase  
    end  

// a conditional assignment for the signal "sda"
// if "sda_link" is true (1), then "sda" takes the value of "sda_register"
// otherwise, it takes a high-impedance value '1'bz'
assign sda   = sda_link ? sda_register: 1'bz;  

// assigns the value of "data_register" to "data"
// essentially, "data" will always have the same value as "data_register"
assign data  = data_register;

endmodule
