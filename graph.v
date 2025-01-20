`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/20/2025 01:54:01 PM
// Design Name: 
// Module Name: graph
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

module graph(
   input clk,  // Clock input
   input reset,  // Reset input
   input [3:0] btn,  // Paddle controls: btn[0] = right paddle up, btn[1] = right paddle down, btn[2] = left paddle up, btn[3] = left paddle down
   input gra_still,  // Indicates still graphics (e.g., new game or game over states)
   input video_on,  // Signal to enable video display
   input [9:0] x,  // Current pixel x-coordinate
   input [9:0] y,  // Current pixel y-coordinate
   output graph_on,  // Signal to enable graphics rendering
   output reg l_hit, l_mis, r_hit, r_mis,  // Ball hit/miss signals for left and right paddles
   output reg [11:0] graph_rgb  // RGB output for graphics
);
    
   // Screen boundaries
   parameter X_MAX = 639;  // Maximum x-coordinate
   parameter Y_MAX = 479;  // Maximum y-coordinate
    
   // Refresh tick for 60Hz update rate
   wire refresh_tick;
   assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0;  // Triggered at vertical sync
    
   // Wall boundaries
   parameter T_WALL_T = 64;    // Top wall top boundary
   parameter T_WALL_B = 71;    // Top wall bottom boundary (8 pixels thick)
   parameter B_WALL_T = 476;   // Bottom wall top boundary
   parameter B_WALL_B = 479;   // Bottom wall bottom boundary (8 pixels thick)

   // Paddle parameters
   parameter PAD_HEIGHT = 100;  // Paddle height
   parameter PAD_VELOCITY = 4;  // Paddle movement velocity

   // Center area boundaries
   parameter center_l = 317;  // Center left boundary
   parameter center_r = 321;  // Center right boundary
   parameter center_t = 72;   // Center top boundary
   parameter center_b = 475;  // Center bottom boundary

   // Right paddle parameters
   parameter X_RPAD_L = 600;  // Right paddle left boundary
   parameter X_RPAD_R = 606;  // Right paddle right boundary (6 pixels wide)
   reg [9:0] y_rpad_reg = 204;  // Right paddle initial y-coordinate
   reg [9:0] y_rpad_next;
   wire [9:0] y_rpad_t, y_rpad_b;  // Right paddle top and bottom coordinates

   // Left paddle parameters
   parameter X_LPAD_L = 32;   // Left paddle left boundary
   parameter X_LPAD_R = 38;   // Left paddle right boundary (6 pixels wide)
   reg [9:0] y_lpad_reg = 204;  // Left paddle initial y-coordinate
   reg [9:0] y_lpad_next;
   wire [9:0] y_lpad_t, y_lpad_b;  // Left paddle top and bottom coordinates

   // Ball parameters
   parameter BALL_SIZE = 8;   // Ball size (width and height)
   wire [9:0] x_ball_l, x_ball_r, y_ball_t, y_ball_b;  // Ball boundaries
   reg [9:0] y_ball_reg, x_ball_reg;  // Ball position registers
   wire [9:0] y_ball_next, x_ball_next;  // Ball next position
   reg [9:0] x_delta_reg, x_delta_next;  // Ball x-direction velocity
   reg [9:0] y_delta_reg, y_delta_next;  // Ball y-direction velocity

   // Ball velocity parameters
   parameter BALL_VELOCITY_POS = 1.0;    // Positive ball velocity
   parameter BALL_VELOCITY_NEG = -1.0;   // Negative ball velocity

   // ROM for ball shape
   wire [2:0] rom_addr, rom_col;  // ROM address and column
   reg [7:0] rom_data;  // ROM data for ball shape
   wire rom_bit;  // Bit representing ball pixel

   // Registers and control logic
   always @(posedge clk or posedge reset)
       if (reset) begin
           // Reset paddle and ball positions and velocities
           y_rpad_reg <= 204;
           y_lpad_reg <= 204;
           x_ball_reg <= 0;
           y_ball_reg <= 0;
           x_delta_reg <= 10'h002;
           y_delta_reg <= 10'h002;
       end else begin
           // Update paddle and ball positions and velocities
           y_rpad_reg <= y_rpad_next;
           y_lpad_reg <= y_lpad_next;
           x_ball_reg <= x_ball_next;
           y_ball_reg <= y_ball_next;
           x_delta_reg <= x_delta_next;
           y_delta_reg <= y_delta_next;
       end

   // Ball shape ROM
   always @*
       case (rom_addr)
           3'b000: rom_data = 8'b00111100;
           3'b001: rom_data = 8'b01111110;
           3'b010: rom_data = 8'b11111111;
           3'b011: rom_data = 8'b11111111;
           3'b100: rom_data = 8'b11111111;
           3'b101: rom_data = 8'b11111111;
           3'b110: rom_data = 8'b01111110;
           3'b111: rom_data = 8'b00111100;
       endcase

   // Graphics regions
   wire t_wall_on, b_wall_on, c_on;  // Top wall, bottom wall, and center area indicators

   assign c_on = ((center_l <= x) && (x <= center_r) && (center_t <= y) && (y <= center_b));
   assign t_wall_on = ((T_WALL_T <= y) && (y <= T_WALL_B));
   assign b_wall_on = ((B_WALL_T <= y) && (y <= B_WALL_B));

   // Paddle boundaries and control logic
   assign y_rpad_t = y_rpad_reg;
   assign y_rpad_b = y_rpad_t + PAD_HEIGHT - 1;

   assign y_lpad_t = y_lpad_reg;
   assign y_lpad_b = y_lpad_t + PAD_HEIGHT - 1;

   always @* begin
       // Default paddle positions
       y_rpad_next = y_rpad_reg;
       y_lpad_next = y_lpad_reg;

       if (refresh_tick) begin
           // Right paddle control
           if (btn[1] & (y_rpad_b < (B_WALL_T - 1 - PAD_VELOCITY)))
               y_rpad_next = y_rpad_reg + PAD_VELOCITY;
           else if (btn[0] & (y_rpad_t > (T_WALL_B - 1 - PAD_VELOCITY)))
               y_rpad_next = y_rpad_reg - PAD_VELOCITY;

           // Left paddle control
           if (btn[3] & (y_lpad_b < (B_WALL_T - 1 - PAD_VELOCITY)))
               y_lpad_next = y_lpad_reg + PAD_VELOCITY;
           else if (btn[2] & (y_lpad_t > (T_WALL_B - 1 - PAD_VELOCITY)))
               y_lpad_next = y_lpad_reg - PAD_VELOCITY;
       end
   end

   // Ball position and movement logic
   assign x_ball_l = x_ball_reg;
   assign y_ball_t = y_ball_reg;
   assign x_ball_r = x_ball_l + BALL_SIZE - 1;
   assign y_ball_b = y_ball_t + BALL_SIZE - 1;

   assign sq_ball_on = (x_ball_l <= x) && (x <= x_ball_r) &&
                       (y_ball_t <= y) && (y <= y_ball_b);
   assign rom_addr = y[2:0] - y_ball_t[2:0];
   assign rom_col = x[2:0] - x_ball_l[2:0];
   assign rom_bit = rom_data[rom_col];
   assign ball_on = sq_ball_on & rom_bit;

   assign x_ball_next = (gra_still) ? X_MAX / 2 :
                        (refresh_tick) ? x_ball_reg + x_delta_reg : x_ball_reg;
   assign y_ball_next = (gra_still) ? Y_MAX / 2 :
                        (refresh_tick) ? y_ball_reg + y_delta_reg : y_ball_reg;

   // Ball collision and score logic
   always @* begin
       // Reset hit/miss indicators
       l_hit = 1'b0;
       l_mis = 1'b0;
       r_hit = 1'b0;
       r_mis = 1'b0;
       x_delta_next = x_delta_reg;
       y_delta_next = y_delta_reg;

       if (gra_still) begin
           // Set initial ball direction
           x_delta_next = BALL_VELOCITY_NEG;
           y_delta_next = BALL_VELOCITY_POS;
       end else if (y_ball_t < T_WALL_B) begin
           y_delta_next = BALL_VELOCITY_POS;
       end else if (y_ball_b > B_WALL_T) begin
           y_delta_next = BALL_VELOCITY_NEG;
       end else if ((X_LPAD_L <= x_ball_l) && (x_ball_l <= X_LPAD_R) &&
                    (y_lpad_t <= y_ball_b) && (y_ball_t <= y_lpad_b)) begin
           x_delta_next = BALL_VELOCITY_POS;
           l_hit = 1'b1;
       end else if ((X_RPAD_L <= x_ball_r) && (x_ball_r <= X_RPAD_R) &&
                    (y_rpad_t <= y_ball_b) && (y_ball_t <= y_rpad_b)) begin
           x_delta_next = BALL_VELOCITY_NEG;
           r_hit = 1'b1;
       end else if (x_ball_l <= 0) begin
           // Ball misses the left paddle
           x_delta_next = BALL_VELOCITY_POS;
           l_mis = 1'b1;
       end else if (x_ball_r >= X_MAX) begin
           // Ball misses the right paddle
           x_delta_next = BALL_VELOCITY_NEG;
           r_mis = 1'b1;
       end
   end

   // Graphics rendering logic
   always @* begin
       // Default RGB color
       graph_rgb = 12'h000;

       if (~video_on) begin
           graph_rgb = 12'h000; // Black screen if video is off
       end else if (t_wall_on || b_wall_on) begin
           graph_rgb = 12'hF00; // Red walls
       end else if (ball_on) begin
           graph_rgb = 12'h0F0; // Green ball
       end else if (c_on) begin
           graph_rgb = 12'h00F; // Blue center line
       end else if (((X_RPAD_L <= x) && (x <= X_RPAD_R) && (y_rpad_t <= y) && (y <= y_rpad_b)) ||
                    ((X_LPAD_L <= x) && (x <= X_LPAD_R) && (y_lpad_t <= y) && (y <= y_lpad_b))) begin
           graph_rgb = 12'hFFF; // White paddles
       end
   end

   // Enable graphics rendering if any graphical element is active
   assign graph_on = video_on && (t_wall_on || b_wall_on || c_on || ball_on ||
                                  ((X_RPAD_L <= x) && (x <= X_RPAD_R) && (y_rpad_t <= y) && (y <= y_rpad_b)) ||
                                  ((X_LPAD_L <= x) && (x <= X_LPAD_R) && (y_lpad_t <= y) && (y <= y_lpad_b)));

endmodule
