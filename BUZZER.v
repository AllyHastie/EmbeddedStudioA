module BUZZER(
	input clk, // Clock
	input en_buzzer, // Enable
	output reg speaker // Buzzer
);

// internal signals
reg [31:0] tone; // 32-bit counter to give note being played
reg play_music; // 1-bit value to determine if music should be played. 
wire [2:0] octave; // 3-bits to indicate the 5 octaves
wire [3:0] note; // 4-bits to indicate the 5 octaves
wire [7:0] allnotes;// 8-bit variable to store decimal value retrieved from ROM

/******************************************************************************
This function increments the tone counter.
******************************************************************************/
always @(posedge clk)
begin 
	if (en_buzzer) 
	begin
		 if (play_music) begin
			// Continue playing the music
			tone <= tone + 32'd1;
			// The rest of your existing code for playing music
		 end 
		 else 
		 begin
			// Start playing the music
			tone <= 0;
			play_music <= 1;
		 end
	  end 
	  else 
	  begin
		 // Stop playing the music
		 play_music <= 0;
		 tone <= 0;
	  end
end

/******************************************************************************
This function calls the Music ROM module.
******************************************************************************/
music_ROM get_notes(
	.clk(clk), 
	.address(tone[29:22]), 
	.note(allnotes)
);

/******************************************************************************
This function calls the Divide by 12 module.
******************************************************************************/
divide_by_12 note_and_octave(
	.numerator(allnotes[5:0]), // octave and note stored in decimal form
	.quotient(octave), // octave value
	.remainder(note) // note value
);

// internal signal
reg [9:0] clk_divider; // determines frequency of note

/******************************************************************************
This functive determines the clock divider value for a 50mHz clock based
on note being retrieved.
******************************************************************************/
always @*
case(note)
	 0: clk_divider = 10'd1023;//A
	 1: clk_divider = 10'd965;// A#/Bb
	 2: clk_divider = 10'd911;//B
	 3: clk_divider = 10'd861;//C
	 4: clk_divider = 10'd811;// C#/Db
	 5: clk_divider = 10'd767;//D
	 6: clk_divider = 10'd723;// D#/Eb
	 7: clk_divider = 10'd683;//E
	 8: clk_divider = 10'd645;//F
	 9: clk_divider = 10'd607;// F#/Gb
	10: clk_divider = 10'd573;//G
	11: clk_divider = 10'd541;// G#/Ab
	default: clk_divider = 10'd0;
endcase

// Internal signals
reg [9:0] counter_note; 
reg [7:0] counter_octave;

/******************************************************************************
This functive decrements the counter note.
******************************************************************************/
always @(posedge clk) 
counter_note <= counter_note==0 ? clk_divider : counter_note-10'd1;

/******************************************************************************
This functive decrements the counter octave.
******************************************************************************/
always @(posedge clk) 
if(counter_note==0) counter_octave <= counter_octave==0 ? 8'd255 >> octave : counter_octave-8'd1;

/******************************************************************************
This functive inverts speaker value.
******************************************************************************/
always @(posedge clk) 
if(counter_note==0 && counter_octave==0 && allnotes!=0 && tone[21:18]!=0) speaker <= ~speaker;

endmodule


/******************************************************************************
This module divides a given value by 12.
******************************************************************************/
module divide_by_12(
	input [5:0] numerator,  // value to be divided by 12
	output reg [2:0] quotient, // whole numbers
	output [3:0] remainder	// remaining value
);

// Internal signal
reg [1:0] remainder_3to2; // 2-bit register to store partial division value

/******************************************************************************
This functive divides a given value by 12 using a lookup value.
This is first done by dividing the first 4 bits of the numerator by 3.
Dividing by 4 is done by removing 2 bits from the numerator and storing it in
the remainder.
******************************************************************************/
always @(numerator[5:2])
case(numerator[5:2])
	 0: begin quotient=0; remainder_3to2=0; end // 0/3 = 0 r 0
	 1: begin quotient=0; remainder_3to2=1; end // 1/3 = 0 r 1
	 2: begin quotient=0; remainder_3to2=2; end // 2/3 = 0 r 2
	 3: begin quotient=1; remainder_3to2=0; end // 3/3 = 1 r 0
	 4: begin quotient=1; remainder_3to2=1; end // 4/3 = 1 r 1
	 5: begin quotient=1; remainder_3to2=2; end // 5/3 = 1 r 2
	 6: begin quotient=2; remainder_3to2=0; end // 6/3 = 2 r 0
	 7: begin quotient=2; remainder_3to2=1; end // 7/3 = 2 r 1
	 8: begin quotient=2; remainder_3to2=2; end // 8/3 = 2 r 2
	 9: begin quotient=3; remainder_3to2=0; end // 9/3 = 3 r 0
	10: begin quotient=3; remainder_3to2=1; end // 10/3 = 3 r 1
	11: begin quotient=3; remainder_3to2=2; end // 11/3 = 3 r 2
	12: begin quotient=4; remainder_3to2=0; end // 12/3 = 4 r 0
	13: begin quotient=4; remainder_3to2=1; end // 13/3 = 4 r 1
	14: begin quotient=4; remainder_3to2=2; end // 14/3 = 4 r 2
	15: begin quotient=5; remainder_3to2=0; end // 15/3 = 5 r 0
endcase

// Remaining Value using lookup tables remainder_3to2 and the unused numerator values to determine remainder
assign remainder[1:0] = numerator[1:0];  // the first 2 bits are stored into the remainder
assign remainder[3:2] = remainder_3to2;  // and the last 2 bits come from the case statement
endmodule


/******************************************************************************
This module retrieves the song stored in ROM.
******************************************************************************/
module music_ROM(
	input clk, // Clock
	input [6:0] address, //Address of note
	output reg [7:0] note // Note in decimal value
);

/******************************************************************************
This function retrieves the note stored in each ROM address using a case 
statement.
Song Stored aimed to be Super Mario Brothers Theme song
******************************************************************************/
always @(posedge clk)
case(address)
	  0: note<= 7'd19; //E 
	  1: note<= 7'd19; 
	  2: note<= 7'd0; 
	  3: note<= 7'd19; //E
	  4: note<= 7'd19; 
	  5: note<= 7'd0; 
	  6: note<= 7'd19; //E
	  7: note<= 7'd19; 
	  8: note<= 7'd0; 
	  9: note<= 7'd15; //C
	 10: note<= 7'd15; 
	 11: note<= 7'd0; 
	 12: note<= 7'd19; //E
	 13: note<= 7'd19; 
	 14: note<= 7'd0; 
	 15: note<= 7'd22; //G
	 16: note<= 7'd22; 
	 17: note<= 7'd0; 
	 18: note<= 7'd0; 
	 19: note<= 7'd0; 
	 20: note<= 7'd0; 
	 21: note<= 7'd0; 
	 22: note<= 7'd0; 
	 23: note<= 7'd0; 
	 24: note<= 7'd10; //G
	 25: note<= 7'd10; 
	 26: note<= 7'd0; 
	 27: note<= 7'd0; 
	 28: note<= 7'd0; 
	 29: note<= 7'd0; 
	 30: note<= 7'd0; 
	 31: note<= 7'd0; 
	 32: note<= 7'd0; 
	 33: note<= 7'd27; //C
	 34: note<= 7'd27; 
	 35: note<= 7'd0; 
	 36: note<= 7'd0; 
	 37: note<= 7'd0; 
	 38: note<= 7'd22; //G
	 39: note<= 7'd22; 
	 40: note<= 7'd0; 
	 41: note<= 7'd0; 
	 42: note<= 7'd0; 
	 43: note<= 7'd19; //E
	 44: note<= 7'd19;
	 45: note<= 7'd0;
	 46: note<= 7'd0;
	 47: note<= 7'd24; //A
	 48: note<= 7'd24;
	 49: note<= 7'd0; 
	 50: note<= 7'd26; //B
	 51: note<= 7'd26; 
	 52: note<= 7'd0;
	 53: note<= 7'd25; //A#
	 54: note<= 7'd25;
	 55: note<= 7'd0;
	 56: note<= 7'd24; //A
	 57: note<= 7'd24;
	 58: note<= 7'd0;
	 59: note<= 7'd22; //G
	 60: note<= 7'd22;
	 61: note<= 7'd0;
	 62: note<= 7'd31; //E
	 63: note<= 7'd31;
	 64: note<= 7'd0;
	 65: note<= 7'd22; //G
	 66: note<= 7'd22;
	 67: note<= 7'd0;
	 68: note<= 7'd24; //A
	 69: note<= 7'd24;
	 70: note<= 7'd0;
	 71: note<= 7'd20; //F
	 72: note<= 7'd20;
	 73: note<= 7'd0;
	 74: note<= 7'd22; //G
	 75: note<= 7'd22;
	 76: note<= 7'd0;
	 77: note<= 7'd19; //E
	 78: note<= 7'd19;
	 79: note<= 7'd0;
	 80: note<= 7'd0;
	 81: note<= 7'd0;
	 82: note<= 7'd0;
	 83: note<= 7'd29; //D
	 84: note<= 7'd29;
	 85: note<= 7'd0;
	 86: note<= 7'd26; //B
	 87: note<= 7'd26;
	 88: note<= 7'd0;
	 89: note<= 7'd0;
	 90: note<= 7'd0;
	 91: note<= 7'd0;
	 92: note<= 7'd0;
	 93: note<= 7'd0;
	 94: note<= 7'd0;
	 95: note<= 7'd0;
	default: note <= 7'd0;
endcase
endmodule

