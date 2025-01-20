`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/20/2025 02:32:49 PM
// Design Name: 
// Module Name: timer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module timer(
    input wire clk,
    input wire reset,
    input wire timer_start,
    input wire timer_tick,
    output wire timer_up
    );

    // Signal declaration
    reg [6:0] timer_reg = 7'b1111111;  // Timer register with initial value
    reg [6:0] timer_next;

    // Timer state update
    always @(posedge clk or posedge reset) begin
        if (reset)
            timer_reg <= 7'b1111111;    // Reset the timer to the maximum value
        else
            timer_reg <= timer_next;   // Update timer to the next state
    end

    // Timer next-state logic
    always @* begin
        if (timer_start) 
            timer_next = 7'b1111111;   // Start the timer at the maximum value
        else if (timer_tick && timer_reg != 0)
            timer_next = timer_reg - 1; // Decrement the timer
        else
            timer_next = timer_reg;   // Hold the current value
    end

    // Output logic
    assign timer_up = (timer_reg == 0); // Timer is up when it reaches 0

endmodule
