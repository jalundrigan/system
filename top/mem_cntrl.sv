module mem_cntrl
      #(
        parameter ADDR_WIDTH,
        parameter DATA_WIDTH
      )
      (
        input logic clk,
        input logic rst,

        /*
          Interface to high level blocks
        */
        input logic[ADDR_WIDTH-1:0] p0_mem_addr,
        input logic[DATA_WIDTH-1:0] p0_mem_data_in,
        input logic p0_mem_r_en,
        input logic p0_mem_w_en,

        output logic p0_mem_rdy,
        output logic p0_mem_cplt,

        input logic[ADDR_WIDTH-1:0] p1_mem_addr,
        input logic[DATA_WIDTH-1:0] p1_mem_data_in,
        input logic p1_mem_r_en,
        input logic p1_mem_w_en,

        output logic p1_mem_rdy,
        output logic p1_mem_cplt,

        output logic[DATA_WIDTH-1:0] mem_data_out,

        /*
          Interface to DRAM
        */
        output logic cke,
        output logic cs_n,
        output logic ras_n,
        output logic cas_n,
        output logic we_n,
        output logic ldqm,
        output logic udqm,

        output logic [1:0] bs,
        output logic [12:0] a,
        output logic sdram_clk,

        inout [15:0] dq

`ifndef DISPLAY_PC
        /*
          Interface to 7 segment
        */
        ,
        output logic [5:0] seg_sel,
        output logic [7:0] seg_data
`endif

`ifdef SIMULATION
        ,
        input logic [15:0] mem_map_init_addresses,
        input logic [15:0] mem_map_init_values
`endif
      );

enum logic [1:0] {
                    S_P0,
                    S_P1
                 } state;

logic[ADDR_WIDTH-1:0] mem_addr;
logic[DATA_WIDTH-1:0] mem_data_in;
logic mem_r_en;
logic mem_w_en;
logic mem_rdy;
logic mem_cplt;

/*
   DRAM Memory driver
*/
logic dram_mem_r_en;
logic dram_mem_w_en;
logic[DATA_WIDTH-1:0] dram_mem_data_out;
logic dram_mem_rdy;
logic dram_mem_cplt;

assign sdram_clk = clk;

mem_driver  #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH)
            )
            MEM_DRV
            (
                .clk(clk),
                .rst(rst),

                .mem_addr(mem_addr),
                .mem_data_in(mem_data_in),
                .mem_r_en(dram_mem_r_en),
                .mem_w_en(dram_mem_w_en),

                .mem_data_out(dram_mem_data_out),
                .mem_rdy(dram_mem_rdy),
                .mem_cplt(dram_mem_cplt),

                .cke(cke),
                .cs_n(cs_n),
                .ras_n(ras_n),
                .cas_n(cas_n),
                .we_n(we_n),
                .ldqm(ldqm),
                .udqm(udqm),
                .bs(bs),
                .a(a),
                .dq(dq)
            );

assign mem_rdy = dram_mem_rdy;

`ifdef DISPLAY_PC

assign dram_mem_r_en = mem_r_en;
assign dram_mem_w_en = mem_w_en;
assign mem_data_out = dram_mem_data_out;
assign mem_cplt = dram_mem_cplt;

`else
/*
   Seven segment driver
*/
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

logic read_io;
logic write_io;
logic io_request;
logic [15:0] seg_val_mapped_address;

always_comb 
begin

  dram_mem_r_en <= mem_r_en;
  dram_mem_w_en <= mem_w_en;
  read_io <= 1'b0;
  write_io <= 1'b0;

  if(mem_rdy == 1'b1 && mem_addr == seg_val_mapped_address)
  begin
    if(mem_r_en == 1'b1)
    begin
      dram_mem_r_en <= 1'b0;
      read_io <= 1'b1;
    end
    else
    if(mem_w_en == 1'b1)
    begin
      dram_mem_w_en <= 1'b0;
      write_io <= 1'b1;
    end
  end

  if(io_request == 1'b1)
  begin
    mem_data_out <= seg_val[15:0];
    mem_cplt <= 1'b1;
  end
  else
  begin
    mem_data_out <= dram_mem_data_out;
    mem_cplt <= dram_mem_cplt;
  end

end

always_ff @(posedge clk or posedge rst)
begin
    
  if(rst == 1'b1)
  begin

`ifdef SIMULATION
    seg_val_mapped_address <= mem_map_init_addresses;
`else
    seg_val_mapped_address <= 16'h100;
`endif

`ifdef SIMULATION
    seg_val[23:0] <= {8'b0, mem_map_init_values};
`else
    seg_val[23:0] <= 24'h00BEEF;
`endif

  end
  else
  begin
    io_request <= 1'b0;

    if(read_io == 1'b1)
    begin
      io_request <= 1'b1;
    end
    else
    if(write_io == 1'b1)
    begin
      seg_val[15:0] <= mem_data_in;
      io_request <= 1'b1;
    end

  end

end

`endif

logic p0_request;
logic p1_request;
  
always_comb
begin

  p0_mem_rdy <= mem_rdy;

  if(p0_request == 1'b1)
  begin
    p1_mem_rdy <= 1'b0;
  end
  else
  begin
    p1_mem_rdy <= mem_rdy;
  end
end

always_comb
begin

  if(state == S_P0)
  begin
    p0_mem_cplt <= mem_cplt;
    p1_mem_cplt <= 1'b0;
  end
  else
  if(state == S_P1)
  begin
    p0_mem_cplt <= 1'b0;
    p1_mem_cplt <= mem_cplt;
  end
  else
  begin
    // TODO: can be dont care
    p0_mem_cplt <= 1'b0;
    p1_mem_cplt <= 1'b0;
  end

end

always_comb
begin

  if(mem_rdy == 1'b1 && (p0_mem_r_en == 1'b1 || p0_mem_w_en == 1'b1) )
  begin
    p0_request <= 1'b1;
    p1_request <= 1'b0;

    mem_addr <= p0_mem_addr;
    mem_data_in <= p0_mem_data_in;
    mem_r_en <= p0_mem_r_en;
    mem_w_en <= p0_mem_w_en;
  end
  else
  if(mem_rdy == 1'b1 && (p1_mem_r_en == 1'b1 || p1_mem_w_en == 1'b1) )
  begin
    p0_request <= 1'b0;
    p1_request <= 1'b1;

    mem_addr <= p1_mem_addr;
    mem_data_in <= p1_mem_data_in;
    mem_r_en <= p1_mem_r_en;
    mem_w_en <= p1_mem_w_en;
  end
  else
  begin
    p0_request <= 1'b0;
    p1_request <= 1'b0;

    mem_addr <= p0_mem_addr;
    mem_data_in <= p0_mem_data_in;
    mem_r_en <= p0_mem_r_en;
    mem_w_en <= p0_mem_w_en;
  end

end

always_ff @(posedge clk or posedge rst)
begin
    
  if(rst == 1'b1)
  begin
    state <= S_P0;
  end
  else
  begin

    if(p0_request == 1'b1)
    begin
      state <= S_P0;
    end
    else
    if(p1_request == 1'b1)
    begin
      state <= S_P1;
    end

  end

end

endmodule
