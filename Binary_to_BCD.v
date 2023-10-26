module Binary_to_BCD(bin, bcd);
// Declare input and output signals and their widths
input [6:0] bin;    // 7 Bit binary input signal
output [11:0] bcd;  // 12 bit BCD output signal

// Internal variables
reg [11:0] bcd;     // 12 bit BCD register
reg [2:0] i;        //3 bit count

/******************************************************************************
This function converts binary to BCD using the Double Dable algorithm.
******************************************************************************/
always @(bin) //only execute whenever there's a change in the 'bin' signal
begin
    bcd = 0; // Initialise bcd to zero.
    for (i = 0; i < 7; i = i + 1) // Start a for loop that will iterate 7 times
    begin
        // Concatenate the value of the current BCD (except its MSB) 
        // with the bit from 'bin' indexed by (6-i). 
        // This is shifting and adding the next bit.
        bcd = {bcd[10:0], bin[6 - i]}; // Concatenation

        // If a hex digit of 'bcd' is more than 4, add 3 to it.
        if (i<6 && bcd[3:0] > 4) // the least significant 4 bits
            bcd[3:0] = bcd[3:0]+3;
        if (i<6 && bcd[7:4] > 4) // the next 4 bits (bits 4 to 7)
            bcd[7:4] = bcd[7:4] + 3;
        if (i<6 && bcd[11:8] > 4) // the most significant 4 bits (bits 8 to 11)
            bcd[11:8] = bcd[11:8] + 3;
    end
end
endmodule 