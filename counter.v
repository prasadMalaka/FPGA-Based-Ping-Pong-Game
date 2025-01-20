`timescale 1ns / 1ps

module counter(
    input clk,              // Clock input
    input reset,            // Reset signal
    input l_d_inc,          // Increment left player's score
    input r_d_inc,          // Increment right player's score
    input d_clr,            // Clear both scores
    output reg [3:0] dig0,  // Units place of right player's score
    output reg [3:0] dig1,  // Tens place of right player's score
    output reg [3:0] dig2,  // Units place of left player's score
    output reg [3:0] dig3   // Tens place of left player's score
);

    // Sequential logic for updating the score counters
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset scores to 0
            dig0 <= 0;
            dig1 <= 0;
            dig2 <= 0;
            dig3 <= 0;
        end
        else if (d_clr) begin
            // Clear scores to 0
            dig0 <= 0;
            dig1 <= 0;
            dig2 <= 0;
            dig3 <= 0;
        end
        else begin
            // Increment right player's score
            if (r_d_inc) begin
                if (dig0 == 9) begin
                    dig0 <= 0;
                    if (dig1 == 9)
                        dig1 <= 0;
                    else
                        dig1 <= dig1 + 1;
                end
                else begin
                    dig0 <= dig0 + 1;
                end
            end

            // Increment left player's score
            if (l_d_inc) begin
                if (dig2 == 9) begin
                    dig2 <= 0;
                    if (dig3 == 9)
                        dig3 <= 0;
                    else
                        dig3 <= dig3 + 1;
                end
                else begin
                    dig2 <= dig2 + 1;
                end
            end
        end
    end

endmodule
