module vga_driver
        (
            input logic clk,
            input logic rst,

            input logic[4:0] pixel_red,
            input logic[5:0] pixel_green,
            input logic[4:0] pixel_blue,

            output logic[4:0] vga_red,
            output logic[5:0] vga_green,
            output logic[4:0] vga_blue,

            output logic next_pixel,

            output logic h_sync,
            output logic v_sync
        );

parameter H_ACTIVE = 10'd640;
parameter H_FRONT_PORCH = 10'd16;
parameter H_SYNC_PULSE = 10'd96;
parameter H_BACK_PORCH = 10'd48;

parameter H_COUNT = H_ACTIVE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;
parameter H_SYNC_LOW = H_ACTIVE + H_FRONT_PORCH;
parameter H_SYNC_HIGH = H_ACTIVE + H_FRONT_PORCH + H_SYNC_PULSE - 10'd1;

parameter V_ACTIVE = 10'd480;
parameter V_FRONT_PORCH = 10'd11;
parameter V_SYNC_PULSE = 10'd2;
parameter V_BACK_PORCH = 10'd31;

parameter V_COUNT = V_ACTIVE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;
parameter V_SYNC_LOW = V_ACTIVE + V_FRONT_PORCH;
parameter V_SYNC_HIGH = V_ACTIVE + V_FRONT_PORCH + V_SYNC_PULSE - 10'd1;

logic pixel_clock;
logic [9:0] h_counter;
logic [9:0] v_counter;

always_comb
begin
    if(h_counter < H_ACTIVE && v_counter < V_ACTIVE)
    begin
        vga_red <= pixel_red;
        vga_green <= pixel_green;
        vga_blue <= pixel_blue;
        next_pixel <= pixel_clock;
    end
    else
    begin
        vga_red <= ($bits(vga_red))'('b0);
        vga_green <= ($bits(vga_green))'('b0);
        vga_blue <= ($bits(vga_blue))'('b0);
        next_pixel <= 1'b0;
    end

    if(h_counter >= H_SYNC_LOW && h_counter <= H_SYNC_HIGH)
    begin
        h_sync <= 1'b0;
    end
    else
    begin
        h_sync <= 1'b1;
    end

    if(v_counter >= V_SYNC_LOW && v_counter <= V_SYNC_HIGH)
    begin
        v_sync <= 1'b0;
    end
    else
    begin
        v_sync <= 1'b1;
    end

end

always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
    begin
        pixel_clock <= 1'b0;
    end
    else
    begin
        // 25Mhz pixel clock
        pixel_clock <= ~pixel_clock;
    end
end

always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
    begin
        h_counter <= 10'b0;
    end
    else
    begin
        if(pixel_clock == 1'b1)
        begin
            if(h_counter == H_COUNT - 10'b1)
            begin
                h_counter <= 10'b0;
            end
            else
            begin
                h_counter <= h_counter + 10'b1;
            end
        end
    end
end

always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
    begin
        v_counter <= 10'b0;
    end
    else
    begin
        if(pixel_clock == 1'b1 && h_counter == H_COUNT - 10'b1)
        begin
            if(v_counter == V_COUNT - 10'b1)
            begin
                v_counter <= 10'b0;
            end
            else
            begin
                v_counter <= v_counter + 10'b1;
            end
        end
    end
end

endmodule
