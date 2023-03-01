module display_cntrl
        #(
            parameter MEM_ADDR_WIDTH,
            parameter DATA_WIDTH
        )
        (
            input logic clk,
            input logic rst,

            output logic[4:0] vga_red,
            output logic[5:0] vga_green,
            output logic[4:0] vga_blue,

            output logic h_sync,
            output logic v_sync,

            output logic[MEM_ADDR_WIDTH-1:0] mem_addr,
            output logic[DATA_WIDTH-1:0] mem_data_in,
            output logic mem_r_en,
            output logic mem_w_en,

            input logic[DATA_WIDTH-1:0] mem_data_out,
            input logic mem_rdy,
            input logic mem_cplt
        );

parameter NUM_PIXEL = 640 * 480;
parameter NUM_PIXEL_MEM_LOC = NUM_PIXEL / 16;

// midway point: 55935
parameter MEM_TOP = 24'd65535;//(MEM_ADDR_WIDTH)'('d65535);
parameter MEM_BASE = 24'd46336;//(MEM_ADDR_WIDTH)'(65536 - NUM_PIXEL_MEM_LOC);

enum logic [1:0] {
                    MEM_READ_START,
                    MEM_READ_CPLT,
                    MEM_READ_WAIT
                 } state;

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


logic [DATA_WIDTH-1:0] next_pixel_buf;
logic [DATA_WIDTH-1:0] this_pixel_buf;
logic [3:0] this_pixel_count;


assign pixel_red = {($bits(pixel_red)){this_pixel_buf[0]}};
assign pixel_green = {($bits(pixel_green)){this_pixel_buf[0]}};
assign pixel_blue = {($bits(pixel_blue)){this_pixel_buf[0]}};

assign mem_w_en = 1'b0;
assign mem_data_in = 16'b0;

always_comb
begin
    if(state == MEM_READ_START && mem_rdy == 1'b1)
    begin
        mem_r_en <= 1'b1;
    end
    else
    begin
        mem_r_en <= 1'b0;
    end
end

always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
    begin
        vga_enable <= 1'b0;
        next_pixel_buf <= ($bits(next_pixel_buf))'('b0);
        this_pixel_buf <= ($bits(this_pixel_buf))'('b0);
        this_pixel_count <= 4'd0;
        mem_addr <= MEM_BASE;
        state <= MEM_READ_START;
    end
    else
    begin

        if(next_pixel == 1'b1 && this_pixel_count < 4'd15)
        begin
            this_pixel_count <= this_pixel_count + 4'd1;
            for(int i = 0;i < 15;i ++)
            begin
                this_pixel_buf[i] <= this_pixel_buf[i + 1];
            end
        end

        if(state == MEM_READ_START)
        begin
            if(mem_rdy == 1'b1)
            begin
                state <= MEM_READ_CPLT;
            end
        end
        else
        if(state == MEM_READ_CPLT)
        begin
            if(mem_cplt == 1'b1)
            begin
                next_pixel_buf <= mem_data_out;
                state <= MEM_READ_WAIT;
            end
        end
        else
        if(state == MEM_READ_WAIT)
        begin
            if(vga_enable == 1'b0 || (this_pixel_count == 4'd15 && next_pixel == 1'b1) )
            begin
                this_pixel_buf <= next_pixel_buf;
                this_pixel_count <= 4'd0;
                vga_enable <= 1'b1;
                state <= MEM_READ_START;
                if(mem_addr == MEM_TOP)
                begin
                    mem_addr <= MEM_BASE;
                end
                else
                begin
                    mem_addr <= mem_addr + 24'd1;
                end
            end
        end

    end
end

/* Handy for simple hard wires images
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
*/

endmodule
