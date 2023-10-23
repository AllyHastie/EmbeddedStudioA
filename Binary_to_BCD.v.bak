module Binary_to_BCD(bin, bcd);
  // Input ports and their sizes
input [6:0] bin;
// Output ports and their size
output [11:0] bcd;
// Internal variables
reg [11:0] bcd;
reg [2:0] i;

// Always block - implement the Double Dabble algorithm
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
endmodule // Binary_to_BCD