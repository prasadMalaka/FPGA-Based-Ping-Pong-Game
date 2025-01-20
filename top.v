`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/20/2025 01:54:01 PM
// Design Name: 
// Module Name: top
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

module top(
    input clk,              // 100MHz
    input reset,            // btnR
    input [3:0] btn,        // btn[0]: up (right paddle), btn[1]: down (right paddle),
                            // btn[2]: up (left paddle), btn[3]: down (left paddle)
    output hsync,           // to VGA Connector
    output vsync,           // to VGA Connector
    output [11:0] rgb       // to DAC, to VGA Connector
    );
    
    parameter newgame = 2'b00;
    parameter play    = 2'b01;
    parameter newball = 2'b10;
    parameter over    = 2'b11;
  
    reg [1:0] state_reg, state_next;
    wire [9:0] w_x, w_y;
    wire w_vid_on, w_p_tick, graph_on, l_hit, l_mis, r_hit, r_mis;
    wire [3:0] text_on;
    wire [11:0] graph_rgb, text_rgb;
    reg [11:0] rgb_reg, rgb_next;
    wire [3:0] dig0, dig1, dig2, dig3;
    reg gra_still, l_d_inc, r_d_inc, d_clr, timer_start;
    wire timer_tick, timer_up;
    reg [1:0] ball_reg, ball_next;
    
    vga_controller vga_unit(
        .clk_100MHz(clk),
        .reset(reset),
        .video_on(w_vid_on),
        .hsync(hsync),
        .vsync(vsync),
        .p_tick(w_p_tick),
        .x(w_x),
        .y(w_y));
    
    text text_unit(
        .clk(clk),
        .x(w_x),
        .y(w_y),
        .dig0(dig0),
        .dig1(dig1),
        .dig2(dig2),
        .dig3(dig3),
        .ball(ball_reg),
        .text_on(text_on),
        .text_rgb(text_rgb));
        
    graph graph_unit(
        .clk(clk),
        .reset(reset),
        .btn(btn),           
        .gra_still(gra_still),
        .video_on(w_vid_on),
        .x(w_x),
        .y(w_y),
        .l_hit(l_hit),
        .l_mis(l_mis),
		.r_hit(r_hit),
		.r_mis(r_mis),
        .graph_on(graph_on),
        .graph_rgb(graph_rgb));
    
    assign timer_tick = (w_x == 0) && (w_y == 0);
    timer timer_unit(
        .clk(clk),
        .reset(reset),
        .timer_tick(timer_tick),
        .timer_start(timer_start),
        .timer_up(timer_up));
    
    counter counter_unit(
        .clk(clk),
        .reset(reset),
        .l_d_inc(l_d_inc),
		.r_d_inc(r_d_inc),
        .d_clr(d_clr),
        .dig0(dig0),
        .dig1(dig1),
		.dig2(dig2),
		.dig3(dig3));
       
    always @(posedge clk or posedge reset)
        if(reset) begin
            state_reg <= newgame;
            ball_reg <= 0;
            rgb_reg <= 0;
        end
    
        else begin
            state_reg <= state_next;
            ball_reg <= ball_next;
            if(w_p_tick)
                rgb_reg <= rgb_next;
        end
    
        // FSMD next state logic
        always @* begin
            gra_still = 1'b1;         // Default: static screen
            timer_start = 1'b0;       // Default: timer not started
            l_d_inc = 1'b0;           // Default: no left paddle score increment
            r_d_inc = 1'b0;           // Default: no right paddle score increment
            d_clr = 1'b0;             // Default: no score clear
            state_next = state_reg;   // Default: remain in current state
            ball_next = ball_reg;     // Default: retain current ball count
    
            case (state_reg)
                // New game state
                newgame: begin
                    ball_next = 2'b11;      // Initialize with 3 balls
                    d_clr = 1'b1;           // Clear scores
                    if (btn != 4'b0000) begin
                        state_next = play;  // Transition to play on button press
                        ball_next = ball_reg - 1;
                    end
                end
    
                // Play state
                play: begin
                    gra_still = 1'b0;       // Enable screen animation
                    if (l_hit)
                        l_d_inc = 1'b1;     // Increment left paddle score
                    else if (r_hit)
                        r_d_inc = 1'b1;     // Increment right paddle score
                    else if (l_mis || r_mis) begin
                        if (ball_reg == 0)
                            state_next = over;  // Transition to game over if no balls left
                        else
                            state_next = newball;  // Otherwise, go to newball state
                        timer_start = 1'b1;       // Start 2-second timer
                        ball_next = ball_reg - 1; // Decrement ball count
                    end
                end
    
                // New ball state: wait for timer and button press
                newball: begin
                    if (timer_up && (btn != 4'b0000)) begin
                        state_next = play;  // Resume play after timer and button press
                    end
                end
    
                // Game over state: display message and reset
                over: begin
                    if (timer_up) begin
                        state_next = newgame;  // Restart the game after timer
                    end
                end
            endcase
        end
    
        // RGB multiplexing
        always @* begin
            if (~w_vid_on)
                rgb_next = 12'h000;  // Blank screen
            else if (text_on[3] || ((state_reg == newgame) && text_on[1]) || ((state_reg == over) && text_on[0]))
                rgb_next = text_rgb;  // Text colors for game states
            else if (graph_on)
                rgb_next = graph_rgb; // Graphical game content
            else if (text_on[2])
                rgb_next = text_rgb;  // Additional text content
            else
                rgb_next = 12'h0F0;   // Default aqua background
        end

    // Output
    assign rgb = rgb_reg;
    
endmodule

