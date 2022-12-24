module top
(
	input logic clk,
	input logic rst_n,

	output logic[3:0] led,
	output logic sdram_clk,     //sdram clock
	output logic sdram_cke,     //sdram clock enable
	output logic sdram_cs_n,    //sdram chip select
	output logic sdram_we_n,    //sdram write enable
	output logic sdram_cas_n,   //sdram column address strobe
	output logic sdram_ras_n,   //sdram row address strobe
	output logic[1:0] sdram_dqm,     //sdram data enable 
	output logic[1:0] sdram_ba,      //sdram bank address
	output logic[12:0] sdram_addr,    //sdram address
	inout [15:0] sdram_dq,       //sdram data
    
    output logic [5:0] seg_sel,
    output logic [7:0] seg_data
);

parameter MEM_ADDR_WIDTH = 24;
parameter DATA_WIDTH = 16;
parameter MEM_SIZE = 65536;

logic[MEM_ADDR_WIDTH-1:0] mem_addr;
logic[DATA_WIDTH-1:0] mem_data_in;
logic mem_r_en;
logic mem_w_en;

logic[DATA_WIDTH-1:0] mem_data_out;
logic mem_rdy;
logic mem_cplt;

logic rst;

assign rst = ~rst_n;

assign sdram_clk = clk;

mem_cntrl   #(
                .ADDR_WIDTH(MEM_ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH),
                .MEM_SIZE(MEM_SIZE)
            )
            MEM
            (
                .clk(clk),
                .rst(rst),

                .mem_addr(mem_addr),
                .mem_data_in(mem_data_in),
                .mem_r_en(mem_r_en),
                .mem_w_en(mem_w_en),

                .mem_data_out(mem_data_out),
                .mem_rdy(mem_rdy),
                .mem_cplt(mem_cplt),

                .cke(sdram_cke),
                .cs_n(sdram_cs_n),
                .ras_n(sdram_ras_n),
                .cas_n(sdram_cas_n),
                .we_n(sdram_we_n),
                .ldqm(sdram_dqm[0]),
                .udqm(sdram_dqm[1]),
                .bs(sdram_ba),
                .a(sdram_addr),
                .dq(sdram_dq)
            );


logic[23:0] seg_val;

logic[7:0] seg_data_invert;
logic[5:0] seg_sel_invert;

assign seg_data = ~seg_data_invert;
assign seg_sel = ~seg_sel_invert;

segment_driver SEG
                (
                    .clk(clk),
                    .rst(rst),

                    .val(seg_val),

                    .sel(seg_sel_invert),
                    .seg_a(seg_data_invert[0]),
                    .seg_b(seg_data_invert[1]),
                    .seg_c(seg_data_invert[2]),
                    .seg_d(seg_data_invert[3]),
                    .seg_e(seg_data_invert[4]),
                    .seg_f(seg_data_invert[5]),
                    .seg_g(seg_data_invert[6]),
                    .dp(seg_data_invert[7])
                );

logic[31:0] timer;

enum logic [3:0] {
                    WRITE, 
                    READ,
                    MEM_WAIT,
                    ERROR
                 } state, next_state;

logic [24:0] burst_size;
logic [24:0] burst_count;
logic [1:0] loop_count;
logic [15:0] write_val_offset;

always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
    begin
        mem_addr <= ($bits(mem_addr))'('b0);
        write_val_offset <= 16'b1;
        mem_data_in <= 16'b0;
        mem_w_en <= 1'b1;
        mem_r_en <= 1'b0;
        led <= 4'b0;
        timer <= 32'b0;
        state <= WRITE;
        seg_val <= ($bits(seg_val))'('b0);
        burst_size <= ($bits(burst_size))'('h1);
        burst_count <= ($bits(burst_count))'('b0);
        loop_count <= 2'b0;
    end
    else
    begin

/* Automatic verification */

        if(state == WRITE)
        begin
            mem_w_en <= 1'b1;
            mem_r_en <= 1'b0;
            mem_data_in <= mem_addr[15:0] + write_val_offset;

            if(mem_rdy == 1'b1 && mem_w_en == 1'b1)
            begin
                if(burst_count == burst_size - ($bits(burst_size))'('d1))
                begin
                    mem_addr <= mem_addr - burst_count[23:0];
                    state <= READ;
                    burst_count <= ($bits(burst_count))'('d0);
                end
                else
                begin
                    mem_addr <= mem_addr + ($bits(mem_addr))'('b1);
                    burst_count <= burst_count + ($bits(burst_count))'('d1);
                end
            end

            if(mem_cplt == 1'b1 && burst_count == ($bits(burst_count))'('d0))
            begin
                seg_val <= mem_addr;//{8'b0, mem_data_out};
                
                if(mem_addr == ($bits(mem_addr))'('h0))
                begin
                    // this considers the case where we roll over and increment write_val_offset
                    if(mem_data_out != (mem_addr[15:0] - 16'd1) + (write_val_offset - ($bits(write_val_offset))'('h1)))
                    begin
                        led <= 4'b1001;
                        // ERROR overides READ in case they are both true
                        state <= ERROR;
                    end
                end
                else
                begin
                    if(mem_data_out != (mem_addr[15:0] - 16'd1) + write_val_offset)
                    begin
                        led <= 4'b1001;
                        // ERROR overides READ in case they are both true
                        state <= ERROR;
                    end
                end
            end

        end
        else
        if(state == READ)
        begin
            mem_w_en <= 1'b0;
            mem_r_en <= 1'b1;

            if(mem_rdy == 1'b1)
            begin
                mem_addr <= mem_addr + ($bits(mem_addr))'('b1);

                if(burst_count == burst_size - ($bits(burst_size))'('d1))
                begin
                    state <= WRITE;
                    burst_count <= ($bits(burst_count))'('d0);

                    if(mem_addr == ($bits(mem_addr))'('hFFFFFF))
                    begin
                        
                        write_val_offset <= write_val_offset + 16'h1;

                        if(loop_count == 2'b1)
                        begin
                            loop_count <= 2'b0;

                            if(burst_size == ($bits(burst_size))'('h1))
                            begin
                                burst_size <= ($bits(burst_size))'('h1000000);
                            end
                            else
                            begin
                                burst_size <= ($bits(burst_size))'('h1);
                            end
                        end
                        else
                        begin
                            loop_count <= loop_count + 2'b1;
                        end

                    end
                end
                else
                begin
                    burst_count <= burst_count + ($bits(burst_count))'('d1);
                end

                if(burst_count > ($bits(burst_count))'('d0))
                begin
                    seg_val <= mem_addr;//{8'b0, mem_data_out};
                    if(mem_data_out != (mem_addr[15:0] - 16'd1) + write_val_offset)
                    begin
                        led <= 4'b0110;
                        // ERROR overides WRITE in case they are both true
                        state <= ERROR;
                    end
                end
            end
        end
        else
        if(state == ERROR)
        begin
            state <= ERROR;
            mem_w_en <= 1'b0;
            mem_r_en <= 1'b0;
        end


/* Manual verification */
/*
        mem_w_en <= 1'b0;
        mem_r_en <= 1'b0;

        if(state == WRITE)
        begin
            if(mem_rdy == 1'b1 && mem_w_en == 1'b0)
            begin
                mem_w_en <= 1'b1;
            end
            else
            if(mem_w_en == 1'b1)
            begin
                mem_data_in <= mem_data_in + ($bits(mem_data_in))'('d2);
                if(mem_addr == ($bits(mem_addr))'('hFFFFFF))
                begin
                    mem_addr <= ($bits(mem_addr))'('b0);
                    state <= READ;
                end
                else
                begin
                    mem_addr <= mem_addr + ($bits(mem_addr))'('b1);
                end
            end
        end
        else
        if(state == READ)
        begin
            if(timer == 32'd50000000)
            begin
                if(mem_cplt == 1'b1)
                begin
                    seg_val <= mem_data_out;
                    timer <= 32'b0;
                    led <= ~led;
                    mem_addr <= mem_addr + ($bits(mem_addr))'('b1);
                end
                else
                if(mem_rdy == 1'b1 && mem_r_en == 1'b0)
                begin
                    mem_r_en <= 1'b1;
                end
            end
            else
            begin
                timer <= timer + 32'b1;
            end
        end
*/
    end
end


/*
    Monitor mem_rdy and make sure we keep the memory at max utilization
*/
logic bad_tb;
always_ff @(posedge clk)
begin

    if(rst == 1'b1)
    begin
        bad_tb <= 1'b0;
    end
    else
    begin
        if(mem_rdy == 1'b1)
        begin
            bad_tb <= 1'b1;
            if(bad_tb == 1'b1)
            begin
                $display("Test bench failure! Double MEM_RDY detected!");
                $stop;
            end
        end
        else
        begin
            bad_tb <= 1'b0;
        end

        if(mem_r_en == 1'b0 && mem_w_en == 1'b0)
        begin
            $display("Test bench failure! Both r_en and w_en at 0!");
            $stop;
        end
    end

end


endmodule