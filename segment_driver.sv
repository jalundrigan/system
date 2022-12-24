module segment_driver
        (
            input logic clk,
            input logic rst,

            input logic[23:0] val,

            output logic[5:0] sel,
            output logic seg_a,
            output logic seg_b,
            output logic seg_c,
            output logic seg_d,
            output logic seg_e,
            output logic seg_f,
            output logic seg_g,
            output logic dp
        );

logic[3:0] selected_char;
logic[15:0] timer;

assign dp = 1'b0;

assign selected_char =  (val[3:0] & {4{sel[5]}}) |
                        (val[7:4] & {4{sel[4]}}) |
                        (val[11:8] & {4{sel[3]}}) |
                        (val[15:12] & {4{sel[2]}}) |
                        (val[19:16] & {4{sel[1]}}) |
                        (val[23:20] & {4{sel[0]}});

always_ff @(posedge clk or posedge rst)
begin
    
    if(rst == 1'b1)
    begin
        timer <= 16'b0;
        sel <= 6'b000001;
    end
    else
    begin
        timer <= timer + 16'b1;

        // about 1000 times per second
        if(timer == 16'd50000)
        begin
            timer <= 16'b0;
            sel[5:1] <= sel[4:0];
            sel[0] <= sel[5];
        end

    end

end

always_comb 
begin

    if(selected_char == 4'h0)
    begin
        seg_a <= 1'b1;
        seg_b <= 1'b1;
        seg_c <= 1'b1;
        seg_d <= 1'b1;
        seg_e <= 1'b1;
        seg_f <= 1'b1;
        seg_g <= 1'b0;
    end
    else
    if(selected_char == 4'h1)
    begin
        seg_a <= 1'b0;
        seg_b <= 1'b1;
        seg_c <= 1'b1;
        seg_d <= 1'b0;
        seg_e <= 1'b0;
        seg_f <= 1'b0;
        seg_g <= 1'b0;
    end
    else
    if(selected_char == 4'h2)
    begin
        seg_a <= 1'b1;
        seg_b <= 1'b1;
        seg_c <= 1'b0;
        seg_d <= 1'b1;
        seg_e <= 1'b1;
        seg_f <= 1'b0;
        seg_g <= 1'b1;
    end
    else
    if(selected_char == 4'h3)
    begin
        seg_a <= 1'b1;
        seg_b <= 1'b1;
        seg_c <= 1'b1;
        seg_d <= 1'b1;
        seg_e <= 1'b0;
        seg_f <= 1'b0;
        seg_g <= 1'b1;
    end
    else
    if(selected_char == 4'h4)
    begin
        seg_a <= 1'b0;
        seg_b <= 1'b1;
        seg_c <= 1'b1;
        seg_d <= 1'b0;
        seg_e <= 1'b0;
        seg_f <= 1'b1;
        seg_g <= 1'b1;
    end
    else
    if(selected_char == 4'h5)
    begin
        seg_a <= 1'b1;
        seg_b <= 1'b0;
        seg_c <= 1'b1;
        seg_d <= 1'b1;
        seg_e <= 1'b0;
        seg_f <= 1'b1;
        seg_g <= 1'b1;
    end
    else
    if(selected_char == 4'h6)
    begin
        seg_a <= 1'b1;
        seg_b <= 1'b0;
        seg_c <= 1'b1;
        seg_d <= 1'b1;
        seg_e <= 1'b1;
        seg_f <= 1'b1;
        seg_g <= 1'b1;
    end
    else
    if(selected_char == 4'h7)
    begin
        seg_a <= 1'b1;
        seg_b <= 1'b1;
        seg_c <= 1'b1;
        seg_d <= 1'b0;
        seg_e <= 1'b0;
        seg_f <= 1'b0;
        seg_g <= 1'b0;
    end
    else
    if(selected_char == 4'h8)
    begin
        seg_a <= 1'b1;
        seg_b <= 1'b1;
        seg_c <= 1'b1;
        seg_d <= 1'b1;
        seg_e <= 1'b1;
        seg_f <= 1'b1;
        seg_g <= 1'b1;
    end
    else
    if(selected_char == 4'h9)
    begin
        seg_a <= 1'b1;
        seg_b <= 1'b1;
        seg_c <= 1'b1;
        seg_d <= 1'b1;
        seg_e <= 1'b0;
        seg_f <= 1'b1;
        seg_g <= 1'b1;
    end
    else
    if(selected_char == 4'hA)
    begin
        seg_a <= 1'b1;
        seg_b <= 1'b1;
        seg_c <= 1'b1;
        seg_d <= 1'b0;
        seg_e <= 1'b1;
        seg_f <= 1'b1;
        seg_g <= 1'b1;
    end
    else
    if(selected_char == 4'hB)
    begin
        seg_a <= 1'b0;
        seg_b <= 1'b0;
        seg_c <= 1'b1;
        seg_d <= 1'b1;
        seg_e <= 1'b1;
        seg_f <= 1'b1;
        seg_g <= 1'b1;
    end
    else
    if(selected_char == 4'hC)
    begin
        seg_a <= 1'b1;
        seg_b <= 1'b0;
        seg_c <= 1'b0;
        seg_d <= 1'b1;
        seg_e <= 1'b1;
        seg_f <= 1'b1;
        seg_g <= 1'b0;
    end
    else
    if(selected_char == 4'hD)
    begin
        seg_a <= 1'b0;
        seg_b <= 1'b1;
        seg_c <= 1'b1;
        seg_d <= 1'b1;
        seg_e <= 1'b1;
        seg_f <= 1'b0;
        seg_g <= 1'b1;
    end
    else
    if(selected_char == 4'hE)
    begin
        seg_a <= 1'b1;
        seg_b <= 1'b0;
        seg_c <= 1'b0;
        seg_d <= 1'b1;
        seg_e <= 1'b1;
        seg_f <= 1'b1;
        seg_g <= 1'b1;
    end
    else
    if(selected_char == 4'hF)
    begin
        seg_a <= 1'b1;
        seg_b <= 1'b0;
        seg_c <= 1'b0;
        seg_d <= 1'b0;
        seg_e <= 1'b1;
        seg_f <= 1'b1;
        seg_g <= 1'b1;
    end
    else
    begin
        seg_a <= 1'bx;
        seg_b <= 1'bx;
        seg_c <= 1'bx;
        seg_d <= 1'bx;
        seg_e <= 1'bx;
        seg_f <= 1'bx;
        seg_g <= 1'bx;
    end

end

endmodule