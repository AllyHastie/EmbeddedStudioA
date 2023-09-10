module I2C(
	clk, // Clock input
	reset_n, // Reset signal (Active low)
	scl, // Clock signal for I2C
    sda, // Clock signal for I2C
    data // 16-bit data to be transmitted
);

// Declaring inputs and outputs
input clk;//50MHz fpga clock
input reset_n; // Active-low reset signal
output scl; // Clock output for I2C
inout  sda; // Bidirectional data line for I2C
output [15:0] data; // 16 bit of data received across 2 x 8 bit data frames

// Declaring internal registers
reg [15:0]data_register; // Register to hold 16-bit data
reg scl; // Register to hold SCL (I2C clock) state
reg sda_register; // Register to hold SDA (I2C data) state
reg sda_link; // Register to link SDA state
reg [7:0]scl_cnt; // Counter for SCL clock
reg [2:0]cnt; // General counter
reg [25:0]timer_cnt; // Timer counter
reg [3:0]data_cnt; // Counter for data bits
reg [7:0]address_register; // Register to hold the device address
reg [8:0]state; // Register to hold the state machine state

/******************************************************************************
This function increments the scl count every 5 us.
******************************************************************************/
always@(posedge clk or negedge reset_n)  
    begin  
        if(!reset_n)  
				// resets back to 0 when reset is triggered (negative edge)
            scl_cnt <= 8'd0;  
        else if(scl_cnt == 8'd199)  
            scl_cnt <= 8'd0;  // Reset the counter when it reaches 199
        else  
            scl_cnt <= scl_cnt + 1'b1;  // Increment the SCL counter
    end  

/******************************************************************************
This function implements a state machine based on SCL_CNT.
******************************************************************************/
always@(posedge clk or negedge reset_n)  
    begin  
        if(!reset_n)
				// resets back to state 5 when reset is triggered (negative edge)
            cnt <= 3'd5;  // If reset is active, set the counter to 5
        else   
            case(scl_cnt)  
				8'd49: cnt <= 3'd1;  // When scl_cnt reaches 49, set cnt to 1
				8'd99: cnt <= 3'd2;  // When scl_cnt reaches 99, set cnt to 2
				8'd149: cnt <= 3'd3; // When scl_cnt reaches 149, set cnt to 3
				8'd199: cnt <= 3'd0; // When scl_cnt reaches 199, set cnt to 0
               default: cnt <= 3'd5;  // Otherwise, keep cnt to 5
            endcase  
    end 

// Define macros for SCL states
`define SCL_HIG (cnt == 3'd1)  // SCL high condition
`define SCL_NEG (cnt == 3'd2)  // SCL negative edge condition
`define SCL_LOW (cnt == 3'd3)  // SCL low condition
`define SCL_POS (cnt == 3'd0)  // SCL positive edge condition

// Update scl signal based on cnt value
always@(posedge clk or negedge reset_n)
    begin  
        if(!reset_n)  // If reset is low
            scl <= 1'b0;  // Set scl low
        else if(`SCL_POS)  // If positive edge condition for SCL
            scl <= 1'b1;  // Set scl high
        else if(`SCL_NEG)  // If negative edge condition for SCL
            scl <= 1'b0;  // Set scl low
    end  

/******************************************************************************
This function increments timer_cnt every 1 second.
******************************************************************************/	 
always@(posedge clk or negedge reset_n)  
    begin  
        if(!reset_n)
				// resets back to 0 when reset is triggered (negative edge)
            timer_cnt <= 26'd0;  
        else if(timer_cnt == 26'd49999999)  
            timer_cnt <= 26'd0;  
        else   
            timer_cnt <= timer_cnt + 1'b1;  
    end  

// I2C States
parameter IDLE  = 9'b0_0000_0000, // I2C not busy
             START  = 9'b0_0000_0010, // Start I2C transmission
             ADDRESS    = 9'b0_0000_0100, // Transmission of Addresss 
             ACK1       = 9'b0_0000_1000, // Acknowledgement bit 1
             READ1  = 9'b0_0001_0000, // Read data frame 1 (8 bits)
             ACK2       = 9'b0_0010_0000, // Acknowledgement bit 2
             READ2  = 9'b0_0100_0000, // Read data frame 2 (8 bits) 
             NACK       = 9'b0_1000_0000, // No Acknowledge bit
             STOP       = 9'b1_0000_0000;  // Stop I2C transmission
`define DEVICE_ADDRESS 8'b1001_0001 // LM75 Slave Address 0x91

/******************************************************************************
This function uses I2C communication to transmit 16 bits of data from 
peripherals.
******************************************************************************/  
always@(posedge clk or negedge reset_n)  
    begin  
        if(!reset_n) 
				// Initialise state to IDLE to indicate I2C line is not busy
            begin  
                data_register  <= 16'd0;  
                sda_register       <= 1'b1;  
                sda_link    <= 1'b1;  
                state       <= IDLE;  
                address_register <= 8'd0;  
                data_cnt    <= 4'd0;  
            end  
        else   
            case(state) 
					 // I2C Idle State indicates that the line is not busy
					IDLE:  
                    begin
								// Set SDA to high
                        sda_register   <= 1'b1;  
                        sda_link <= 1'b1; 
								// After 1 second change state to START
                        if(timer_cnt == 26'd49999999)  
                            state <= START;  
                        else  
                            state <= IDLE;  
                    end  
                // I2C start condition occurs when SCL is high and SDA changes from High to Low
					START:
                    begin
                        if(`SCL_HIG)  
                            begin  
										  // Change SDA to low to trigger start
                                sda_register       <= 1'b0;  
                                sda_link    <= 1'b1; 
										  // Store slave address is address register 
                                address_register <= `DEVICE_ADDRESS;
										  // When SDA is set low I2C transmission starts. Change to next state, transmitting the sensor address
                                state           <= ADDRESS;  
                                data_cnt        <= 4'd0;  
                            end  
                        else  
                            state <= START;  
                    end
						  
					 // I2C Address transmission occurs after start condition is set
                ADDRESS:
                    begin  
                        if(`SCL_LOW)  
                            begin  
                                if(data_cnt == 4'd8)  
                                    begin  
                                        state   <= ACK1;  
                                        data_cnt <=  4'd0;  
                                        sda_register <= 1'b1;  
                                        sda_link    <= 1'b0;  
                                    end  
                                else
                                    begin  
                                        state   <= ADDRESS;  
                                        data_cnt <= data_cnt + 1'b1; 
													 // Transfer slave address to SDA register 
                                        case(data_cnt)  
                                            4'd0: sda_register <= address_register[7];
                                            4'd1: sda_register <= address_register[6];
                                            4'd2: sda_register <= address_register[5];
                                            4'd3: sda_register <= address_register[4];
                                            4'd4: sda_register <= address_register[3];
                                            4'd5: sda_register <= address_register[2];
                                            4'd6: sda_register <= address_register[1];
                                            4'd7: sda_register <= address_register[0];
                                            default: ;  
                                        endcase  
                                    end  
                            end  
                        else  
                            state <= ADDRESS;  
                    end 
					 // Acknowlegdment bit
                ACK1:
                    begin  
                        if(!sda && (`SCL_HIG))  
                            state <= READ1;  
                        else if(`SCL_NEG)  
                            state <= READ1;  
                        else  
                            state <= ACK1;  
                    end  
						  
					 // Read data frame 1 (8 bits)
                READ1:
                    begin 
								// If 8 bits have been read and SCL is low change state to acknowledge data frame
                        if((`SCL_LOW) && (data_cnt == 4'd8))
								begin  
                                state   <= ACK2;  
                                data_cnt <= 4'd0;  
                                sda_register <= 1'b1;  
                                sda_link    <= 1'b1;  
                            end  
								// If SCL is high store SDA state in register
                        else if(`SCL_HIG)  
                            begin  
                                data_cnt <= data_cnt + 1'b1;  
                                case(data_cnt)  
                                    4'd0: data_register[15] <= sda;  
                                    4'd1: data_register[14] <= sda;  
                                    4'd2: data_register[13] <= sda;  
                                    4'd3: data_register[12] <= sda;  
                                    4'd4: data_register[11] <= sda;  
                                    4'd5: data_register[10] <= sda;  
                                    4'd6: data_register[9]  <= sda;  
                                    4'd7: data_register[8]  <= sda;  
                                    default: ;  
                                endcase  
                            end  
                        else  
                            state <= READ1;  
                    end
					 // Acknowlegdment bit  
                ACK2:  
                    begin     
                        if(`SCL_LOW)  
                            sda_register <= 1'b0;  
                        else if(`SCL_NEG)  
                            begin  
                                sda_register   <= 1'b1;  
                                sda_link    <= 1'b0;  
                                state       <= READ2;  
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
                                state   <= NACK;  
                                data_cnt <= 4'd0;  
                                sda_register       <= 1'b1;  
                                sda_link    <= 1'b1;  
                            end  
								// If SCL is high store SDA state in register
                        else if(`SCL_HIG)  
                            begin  
                                data_cnt <= data_cnt + 1'b1;  
                                case(data_cnt)  
                                    4'd0: data_register[7] <= sda;  
                                    4'd1: data_register[6] <= sda;  
                                    4'd2: data_register[5] <= sda;  
                                    4'd3: data_register[4] <= sda;  
                                    4'd4: data_register[3] <= sda;  
                                    4'd5: data_register[2] <= sda;  
                                    4'd6: data_register[1]  <= sda;  
                                    4'd7: data_register[0]  <= sda;  
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
                                state <= STOP;
										  // SDA set to high to indicate stop
                                sda_register   <= 1'b0;  
                            end  
                        else  
                            state <= NACK;  
                    end 
					 // I2C stop condition occurs when SCL is high and SDA changes from Low to High
                STOP:  
                    begin  
                        if(`SCL_HIG)  
                            begin  
                                state <= IDLE;  
                                sda_register <= 1'b1;  
                            end  
                        else  
                            state <= STOP;  
                    end  
                default: state <= IDLE;  
            endcase  
    end  
	 
assign sda   = sda_link ? sda_register: 1'bz;  
assign data  = data_register; 
 
endmodule
