`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/20/2025 01:54:01 PM
// Design Name: 
// Module Name: text
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

module text(
    input clk,               // Clock signal
    input [1:0] ball,        // Ball position or state (not used in this module)
    input [3:0] dig0, dig1, dig2, dig3, // BCD digits representing scores for players
    input [9:0] x, y,        // Current pixel coordinates
    output [3:0] text_on,    // Active signals for different text overlays
    output reg [11:0] text_rgb // RGB output for text colors
    );

    // ASCII ROM address signals
    wire [10:0] rom_addr;    // Address for the ASCII ROM
    reg [6:0] char_addr,     // Character address for ASCII ROM
              char_addr_s,   // Character address for score text
              char_addr_l,   // Character address for logo text
              char_addr_o;   // Character address for "Game Over" text
    reg [3:0] row_addr;      // Row address for the current character
    wire [3:0] row_addr_s,   // Row address for score text
               row_addr_l,   // Row address for logo text
               row_addr_o;   // Row address for "Game Over" text
    reg [2:0] bit_addr;      // Bit address for the current character row
    wire [2:0] bit_addr_s,   // Bit address for score text
               bit_addr_l,   // Bit address for logo text
               bit_addr_o;   // Bit address for "Game Over" text
    wire [7:0] ascii_word;   // Data from the ASCII ROM (current character row)
    wire ascii_bit;          // Bit indicating if a pixel belongs to a character
    wire score_on,           // Active signal for score display
         logo_on,            // Active signal for logo display
         over_on;            // Active signal for "Game Over" display

    // ASCII ROM instance
    ascii_rom ascii_unit(.clk(clk), .addr(rom_addr), .data(ascii_word));

    // Score text activation and address calculations
    assign score_on = (y >= 16) && (y < 64) && (x[9:4] < 16); // Score area activation
    assign row_addr_s = y[4:1]; // Row address for score text
    assign bit_addr_s = x[3:1]; // Bit address for score text
    always @* begin
        case(x[7:4])
            4'h0 : char_addr_s = 7'h50; // 'P'
            4'h1 : char_addr_s = 7'h31; // '1'
            4'h2 : char_addr_s = 7'h20; // ' '
            4'h3 : char_addr_s = 7'h53; // 'S'
            4'h4 : char_addr_s = 7'h3A; // ':'
            4'h5 : char_addr_s = {3'b011, dig3}; // Digit 3
            4'h6 : char_addr_s = {3'b011, dig2}; // Digit 2
            4'h7 : char_addr_s = 7'h20; // ' '
            4'h8 : char_addr_s = 7'h20; // ' '
            4'h9 : char_addr_s = 7'h50; // 'P'
            4'hA : char_addr_s = 7'h32; // '2'
            4'hB : char_addr_s = 7'h20; // ' '
            4'hC : char_addr_s = 7'h53; // 'S'
            4'hD : char_addr_s = 7'h3A; // ':'
            4'hE : char_addr_s = {3'b011, dig1}; // Digit 1
            4'hF : char_addr_s = {3'b011, dig0}; // Digit 0
        endcase
    end

    // Logo display activation and address calculations
    assign logo_on = (y >= 64 && y < 128) && (x >= 0 && x < 128); // Logo area activation
    assign row_addr_l = y[6:3]; // Row address for logo text
    assign bit_addr_l = x[3:1]; // Bit address for logo text
    always @* begin
        case (x[7:4])
            4'h0: char_addr_l = 7'h50; // 'P'
            4'h1: char_addr_l = 7'h49; // 'I'
            4'h2: char_addr_l = 7'h4E; // 'N'
            4'h3: char_addr_l = 7'h47; // 'G'
            4'h4: char_addr_l = 7'h20; // ' '
            4'h5: char_addr_l = 7'h50; // 'P'
            4'h6: char_addr_l = 7'h4F; // 'O'
            4'h7: char_addr_l = 7'h4E; // 'N'
            4'h8: char_addr_l = 7'h47; // 'G'
            default: char_addr_l = 7'h20; // ' '
        endcase
    end

    // "Game Over" display activation and address calculations
    assign over_on = (y[9:6] == 3) && (5 <= x[9:5]) && (x[9:5] <= 13); // "Game Over" area activation
    assign row_addr_o = y[5:2]; // Row address for "Game Over" text
    assign bit_addr_o = x[4:2]; // Bit address for "Game Over" text
    always @* begin
        case(x[8:5])
            4'h5 : char_addr_o = 7'h57; // 'W'
            4'h6 : char_addr_o = 7'h49; // 'I'
            4'h7 : char_addr_o = 7'h4E; // 'N'
            4'h8 : char_addr_o = 7'h4E; // 'N'
            4'h9 : char_addr_o = 7'h45; // 'E'
            4'hA : char_addr_o = 7'h52; // 'R'
            4'hB : char_addr_o = 7'h20; // ' '
            4'hC : char_addr_o = ((dig0 * 10 + dig1) > (dig2 * 10 + dig3)) ? 7'h32 : 7'h31; // Winner (Player 1 or 2)
            default : char_addr_o = 7'h20; // ' '
        endcase
    end

    // Multiplexer for ASCII ROM address and RGB output
    always @* begin
        text_rgb = 12'h0F0; // Default background color (green)

        if(score_on) begin
            char_addr = char_addr_s;
            row_addr = row_addr_s;
            bit_addr = bit_addr_s;
            if(ascii_bit)
                text_rgb = 12'hFFF; // White for score text
        end else if(logo_on) begin
            char_addr = char_addr_l;
            row_addr = row_addr_l;
            bit_addr = bit_addr_l;
            if(ascii_bit)
                text_rgb = 12'hFF0; // Yellow for logo
        end else begin
            char_addr = char_addr_o;
            row_addr = row_addr_o;
            bit_addr = bit_addr_o;
            if(ascii_bit)
                text_rgb = 12'hFF; // Red for "Game Over"
        end        
    end

    // Active text signals for score and "Game Over"
    assign text_on = {score_on, over_on};

    // ASCII ROM interface connections
    assign rom_addr = {char_addr, row_addr}; // Combine character and row addresses
    assign ascii_bit = ascii_word[~bit_addr]; // Get the bit value from ASCII ROM
endmodule
