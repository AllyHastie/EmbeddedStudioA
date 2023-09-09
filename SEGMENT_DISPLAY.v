module SEGMENT_DISPLAY(clk,reset_n,segment,data,led);
  
input clk;  
input reset_n;  
input [15:0]data;
output [7:0] segment;
output [3:0] led;

reg [7:0] segment;
reg [3:0] led;
wire [4:0] dataout_buffer;
reg [1:0] display_data;
reg [16:0] delay_cnt;


binary_decimal binary_decimal(
	.reset(reset_n),
	.select(display_data),
	.data(data[14:8]),
	.decimal(data[7]),
	.decimal_digit(dataout_buffer)
);

always@(posedge clk,negedge reset_n)
	begin
		if(!reset_n)
			delay_cnt<=16'd0;
		else if(delay_cnt==16'd50000)
			delay_cnt<=16'd0;  
		else   
			delay_cnt<=delay_cnt +1;  
	end

always@(posedge clk,negedge reset_n)  
	begin
		if(!reset_n)
			display_data<=2'd0;
		else if(delay_cnt==16'd50000)  
			display_data<=display_data + 1'b1;  
		else
			display_data<=display_data;  
	end  
      
always@(display_data)  
	begin   
		case(display_data)  
			2'b00: led = 4'b1110;
			2'b01: led = 4'b1101;
			2'b10: led = 4'b1011;
			2'b11: led = 4'b0111;
			default led = 4'b1111;
		endcase
	end

always@(dataout_buffer)
	begin   
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
			default : segment =8'hc0; //0
		endcase
		if(display_data == 2'b10)
			segment = segment & 8'b01111111; // Add decimal point for second digit
	end

endmodule   