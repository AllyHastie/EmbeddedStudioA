module Binary_to_BCD(bin, bcd);
// Declare input and output signals and their widths
input [6:0] bin; // 7 Bit binary input signal
output [11:0] bcd; // 12 bit BCD output signal
// Internal variables
reg [11:0] bcd; // 12 bit BCD register
reg [2:0] i; //3 bit count
/******************************************************************************
This function converts binary to BCD using the Double Dable algorithm.
******************************************************************************/
always @(bin)
begin
    bcd = 0; // Initialize bcd to zero.
    for (i = 0; i < 7; i = i + 1) // Run for 7 iterations
    begin
        bcd = {bcd[10:0], bin[6 - i]}; // Concatenation

        // If a hex digit of 'bcd' is more than 4, add 3 to it.
        if (i<6 && bcd[3:0] > 4)
            bcd[3:0] = bcd[3:0]+3;
        if (i<6 && bcd[7:4] > 4)
            bcd[7:4] = bcd[7:4] + 3;
        if (i<6 && bcd[11:8] > 4)
            bcd[11:8] = bcd[11:8] + 3;
    end
end
endmodule 