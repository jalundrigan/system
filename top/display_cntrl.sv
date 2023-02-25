module display_cntrl
        (
            input logic clk,
            input logic rst,

            output logic[4:0] vga_red,
            output logic[5:0] vga_green,
            output logic[4:0] vga_blue,

            output logic h_sync,
            output logic v_sync
        );

parameter NUM_PIXEL = 640 * 480;

logic [4:0] pixel_red;
logic [5:0] pixel_green;
logic [4:0] pixel_blue;

logic [9:0] h_count;
logic [9:0] v_count;

logic next_pixel;
logic vga_enable;

vga_driver VGA(
                .clk(clk),
                .rst(rst | ~vga_enable),

                .pixel_red(pixel_red),
                .pixel_green(pixel_green),
                .pixel_blue(pixel_blue),

                .vga_red(vga_red),
                .vga_green(vga_green),
                .vga_blue(vga_blue),

                .next_pixel(next_pixel),

                .h_sync(h_sync),
                .v_sync(v_sync)
                );


always_comb
begin

    if(v_count == 0 || v_count == 480 - 1)
    begin
        pixel_red <= ($bits(pixel_red))'('b0);
        pixel_green <= ($bits(pixel_green))'('b111111);
        pixel_blue <= ($bits(pixel_blue))'('b0);
    end
    else
    if(h_count == 0 || h_count == 640 - 1)
    begin
        pixel_red <= ($bits(pixel_red))'('b0);
        pixel_green <= ($bits(pixel_green))'('b111111);
        pixel_blue <= ($bits(pixel_blue))'('b11111);
    end
    else
    if(v_count < 480 / 2)
    begin
        pixel_red <= ($bits(pixel_red))'('b11111);
        pixel_green <= ($bits(pixel_green))'('b0);
        pixel_blue <= ($bits(pixel_blue))'('b0);
    end
    else
    begin
        pixel_red <= ($bits(pixel_red))'('b0);
        pixel_green <= ($bits(pixel_green))'('b0);
        pixel_blue <= ($bits(pixel_blue))'('b11111);
    end

end


always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
    begin
        h_count <= 10'd0;
        v_count <= 10'd0;
        vga_enable <= 1'b0;
    end
    else
    begin

        vga_enable <= 1'b1;

        if(next_pixel == 1'b1)
        begin
            if(h_count == 640 - 1)
            begin
                h_count <= 10'd0;

                if(v_count == 480 - 1)
                begin
                    v_count <= 10'd0;
                end
                else
                begin
                    v_count <= v_count + 10'd1;
                end
            end
            else
            begin
                h_count <= h_count + 10'd1;
            end
        end
    end
end

endmodule
