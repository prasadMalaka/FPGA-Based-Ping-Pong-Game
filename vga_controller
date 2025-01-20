`timescale 1ns / 1ps

module vga_controller(
    input clk_100MHz,   // 100 MHz clock input from the Basys 3 board
    input reset,        // System reset signal (active high)
    output video_on,    // Active while the pixel counts (x, y) are within the visible display area
    output hsync,       // Horizontal synchronization signal
    output vsync,       // Vertical synchronization signal
    output p_tick,      // 25MHz pixel tick signal, generated from 100MHz clock
    output [9:0] x,     // Current horizontal pixel position (0-799)
    output [9:0] y      // Current vertical pixel position (0-524)
);

    // Horizontal timing parameters
    parameter HD = 640;             // Horizontal display area width in pixels
    parameter HF = 48;              // Horizontal front porch width in pixels
    parameter HB = 16;              // Horizontal back porch width in pixels
    parameter HR = 96;              // Horizontal retrace (sync pulse) width in pixels
    parameter HMAX = HD + HF + HB + HR - 1; // Total horizontal line width in pixels (799)

    // Vertical timing parameters
    parameter VD = 480;             // Vertical display area height in pixels
    parameter VF = 10;              // Vertical front porch height in pixels
    parameter VB = 33;              // Vertical back porch height in pixels
    parameter VR = 2;               // Vertical retrace (sync pulse) height in pixels
    parameter VMAX = VD + VF + VB + VR - 1; // Total vertical frame height in pixels (524)

    // Clock divider for generating the 25MHz pixel clock from the 100MHz input clock
    reg [1:0] r_25MHz;              // 2-bit counter for dividing the clock
    wire w_25MHz;                   // Generated 25MHz clock signal

    always @(posedge clk_100MHz or posedge reset) begin
        if (reset)
            r_25MHz <= 0;           // Reset the clock divider counter
        else
            r_25MHz <= r_25MHz + 1; // Increment the counter
    end

    assign w_25MHz = (r_25MHz == 0) ? 1 : 0; // Generate a pulse at every 4th clock edge

    // Registers to hold current pixel positions and synchronization signals
    reg [9:0] h_count_reg, h_count_next; // Horizontal pixel counter
    reg [9:0] v_count_reg, v_count_next; // Vertical pixel counter
    reg h_sync_reg, v_sync_reg;          // Registers for horizontal and vertical sync signals
    wire h_sync_next, v_sync_next;       // Next state of sync signals

    // Sequential logic for updating counters and sync signals
    always @(posedge clk_100MHz or posedge reset) begin
        if (reset) begin
            h_count_reg <= 0;       // Reset horizontal counter
            v_count_reg <= 0;       // Reset vertical counter
            h_sync_reg <= 0;        // Reset horizontal sync
            v_sync_reg <= 0;        // Reset vertical sync
        end else begin
            h_count_reg <= h_count_next; // Update horizontal counter
            v_count_reg <= v_count_next; // Update vertical counter
            h_sync_reg <= h_sync_next;   // Update horizontal sync
            v_sync_reg <= v_sync_next;   // Update vertical sync
        end
    end

    // Horizontal counter logic
    always @(*) begin
        if (h_count_reg == HMAX)
            h_count_next = 0;       // Reset horizontal counter at the end of the line
        else
            h_count_next = h_count_reg + 1; // Increment horizontal counter
    end

    // Vertical counter logic
    always @(*) begin
        if (h_count_reg == HMAX) begin
            if (v_count_reg == VMAX)
                v_count_next = 0;   // Reset vertical counter at the end of the frame
            else
                v_count_next = v_count_reg + 1; // Increment vertical counter
        end else begin
            v_count_next = v_count_reg; // Hold the current vertical counter value
        end
    end

    // Sync signal generation
    assign h_sync_next = (h_count_reg >= (HD + HB) && h_count_reg < (HD + HB + HR));
    assign v_sync_next = (v_count_reg >= (VD + VB) && v_count_reg < (VD + VB + VR));

    // Video-on signal indicates the pixel is within the active display area
    assign video_on = (h_count_reg < HD) && (v_count_reg < VD);

    // Output assignments
    assign hsync = h_sync_reg;      // Horizontal sync output
    assign vsync = v_sync_reg;      // Vertical sync output
    assign x = h_count_reg;         // Current horizontal pixel position
    assign y = v_count_reg;         // Current vertical pixel position
    assign p_tick = w_25MHz;        // Pixel tick output

endmodule
