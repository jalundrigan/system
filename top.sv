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
   output logic [7:0] seg_data,

   input logic uart_rx,
   output logic uart_tx,

   output logic[4:0] vga_out_r,
   output logic[5:0] vga_out_g,
   output logic[4:0] vga_out_b,
   output logic vga_out_hs,
   output logic vga_out_vs

`ifdef SIMULATION
   ,
   input logic cpu_enable,
   input logic [15:0] mem_map_init_addresses,
   input logic [15:0] mem_map_init_values
`endif
);

parameter MEM_ADDR_WIDTH = 24;
parameter DATA_WIDTH = 16;
parameter REG_ADDR_WIDTH = 4;
parameter REG_FILE_SIZE = 16;

logic rst;
assign rst = ~rst_n;

// CPU mem lines
logic[MEM_ADDR_WIDTH-1:0] cpu_mem_addr;
logic[DATA_WIDTH-1:0] cpu_mem_data_in;
logic cpu_mem_r_en;
logic cpu_mem_w_en;
logic cpu_mem_rdy;
logic cpu_mem_cplt;

// System init mem lines
logic[MEM_ADDR_WIDTH-1:0] init_mem_addr;
logic[DATA_WIDTH-1:0] init_mem_data_in;
logic init_mem_r_en;
logic init_mem_w_en;
logic init_mem_rdy;
logic init_mem_cplt;

// Display mem lines
logic[MEM_ADDR_WIDTH-1:0] disp_mem_addr;
logic[DATA_WIDTH-1:0] disp_mem_data_in;
logic disp_mem_r_en;
logic disp_mem_w_en;
logic disp_mem_rdy;
logic disp_mem_cplt;

// Memory high priority
logic[MEM_ADDR_WIDTH-1:0] p0_mem_addr;
logic[DATA_WIDTH-1:0] p0_mem_data_in;
logic p0_mem_r_en;
logic p0_mem_w_en;
logic p0_mem_rdy;
logic p0_mem_cplt;

// Memory controller low priority
logic[MEM_ADDR_WIDTH-1:0] p1_mem_addr;
logic[DATA_WIDTH-1:0] p1_mem_data_in;
logic p1_mem_r_en;
logic p1_mem_w_en;
logic p1_mem_rdy;
logic p1_mem_cplt;

// Shared memory data out
logic[DATA_WIDTH-1:0] mem_data_out;

/*
   UART serial driver
*/
parameter CLK_SPEED = 50000000;
parameter BAUD_RATE = 115200;

logic [7:0] serial_data_out;
logic serial_out_rdy;
logic serial_out_en;

logic [7:0] serial_data_in;
logic serial_in_cplt;
logic serial_in_error;

serial_driver #(
                .CLK_SPEED(CLK_SPEED),
                .BAUD_RATE(BAUD_RATE)
               )
               SER
               (
                  .clk(clk),
                  .rst(~rst_n),

                  .data_out(serial_data_out),
                  .serial_out_en(serial_out_en),
                  .serial_out_rdy(serial_out_rdy),

                  .data_in(serial_data_in),
                  .serial_in_cplt(serial_in_cplt),
                  .serial_in_error(serial_in_error),

                  .uart_rx(uart_rx),
                  .uart_tx(uart_tx)
               );


/*
   System Initialization
*/
`ifndef SIMULATION
logic cpu_enable;
`endif

system_init #(
               .ADDR_WIDTH(MEM_ADDR_WIDTH),
               .DATA_WIDTH(DATA_WIDTH)
            )
            INIT
            (
               .clk(clk),
               .rst_n(rst_n),

               .mem_data_out(mem_data_out),
               .serial_in_error(serial_in_error),
               .serial_in_cplt(serial_in_cplt),
               .serial_data_in(serial_data_in),
               .serial_out_rdy(serial_out_rdy),
               .mem_rdy(init_mem_rdy),
               .mem_cplt(init_mem_cplt),

               .serial_data_out(serial_data_out),
               .serial_out_en(serial_out_en),
               .led(led),
               .mem_w_en(init_mem_w_en),
               .mem_r_en(init_mem_r_en),
               .mem_addr(init_mem_addr),
               .mem_data_in(init_mem_data_in)

`ifndef SIMULATION
               ,
               .cpu_enable(cpu_enable)
`endif
            );

/*
   CPU
*/

`ifdef DISPLAY_PC
   logic[MEM_ADDR_WIDTH-1:0] pc;
`endif

cpu  #(
         .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
         .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
         .DATA_WIDTH(DATA_WIDTH),
         .REG_FILE_SIZE(REG_FILE_SIZE)
      )
      CPU
      (
         .clk(clk),
         .rst(rst | ~cpu_enable),

         .mem_addr(cpu_mem_addr),
         .mem_data_in(cpu_mem_data_in),
         .mem_r_en(cpu_mem_r_en),
         .mem_w_en(cpu_mem_w_en),

         .mem_data_out(mem_data_out),
         .mem_rdy(cpu_mem_rdy),
         .mem_cplt(cpu_mem_cplt)

`ifdef DISPLAY_PC
         ,
         .pc(pc)
`endif
      );


assign p0_mem_addr      = cpu_enable == 1'b0 ? init_mem_addr : disp_mem_addr;
assign p0_mem_data_in   = cpu_enable == 1'b0 ? init_mem_data_in : disp_mem_data_in;
assign p0_mem_r_en      = cpu_enable == 1'b0 ? init_mem_r_en : disp_mem_r_en;
assign p0_mem_w_en      = cpu_enable == 1'b0 ? init_mem_w_en : disp_mem_w_en;

assign p1_mem_addr      = cpu_mem_addr;
assign p1_mem_data_in   = cpu_mem_data_in;
assign p1_mem_r_en      = cpu_mem_r_en;
assign p1_mem_w_en      = cpu_mem_w_en;

assign init_mem_rdy      = p0_mem_rdy;
assign init_mem_cplt     = p0_mem_cplt;

assign disp_mem_rdy      = p0_mem_rdy;
assign disp_mem_cplt     = p0_mem_cplt;

assign cpu_mem_rdy       = p1_mem_rdy;
assign cpu_mem_cplt      = p1_mem_cplt;

/*
   Memory Controller
*/
mem_cntrl  #(
                .ADDR_WIDTH(MEM_ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH)
            )
            MEM_CTRL
            (
                .clk(clk),
                .rst(rst),

                .p0_mem_addr(p0_mem_addr),
                .p0_mem_data_in(p0_mem_data_in),
                .p0_mem_r_en(p0_mem_r_en),
                .p0_mem_w_en(p0_mem_w_en),

                .p0_mem_rdy(p0_mem_rdy),
                .p0_mem_cplt(p0_mem_cplt),

                .p1_mem_addr(p1_mem_addr),
                .p1_mem_data_in(p1_mem_data_in),
                .p1_mem_r_en(p1_mem_r_en),
                .p1_mem_w_en(p1_mem_w_en),

                .p1_mem_rdy(p1_mem_rdy),
                .p1_mem_cplt(p1_mem_cplt),

                .mem_data_out(mem_data_out),

                .cke(sdram_cke),
                .cs_n(sdram_cs_n),
                .ras_n(sdram_ras_n),
                .cas_n(sdram_cas_n),
                .we_n(sdram_we_n),
                .ldqm(sdram_dqm[0]),
                .udqm(sdram_dqm[1]),
                .bs(sdram_ba),
                .a(sdram_addr),
                .sdram_clk(sdram_clk),
                .dq(sdram_dq)
`ifndef DISPLAY_PC
                ,
                .seg_sel(seg_sel),
                .seg_data(seg_data)
`endif

`ifdef SIMULATION
               ,
               .mem_map_init_addresses(mem_map_init_addresses),
               .mem_map_init_values(mem_map_init_values)
`endif
            );


`ifdef DISPLAY_PC
/*
   Seven segment driver
*/
logic[23:0] seg_val;

logic[7:0] seg_data_invert;
logic[5:0] seg_sel_invert;

assign seg_data = ~seg_data_invert;
assign seg_sel = ~seg_sel_invert;

assign seg_val[15:0] = pc;
assign seg_val[23:16] = 8'b0;

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
`endif

display_cntrl  #(
                  .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
                  .DATA_WIDTH(DATA_WIDTH)
                )
                DISP
                (
                  .clk(clk),
                  .rst(rst | ~cpu_enable),

                  .vga_red(vga_out_r),
                  .vga_green(vga_out_g),
                  .vga_blue(vga_out_b),

                  .h_sync(vga_out_hs),
                  .v_sync(vga_out_vs),

                  .mem_addr(disp_mem_addr),
                  .mem_data_in(disp_mem_data_in),
                  .mem_r_en(disp_mem_r_en),
                  .mem_w_en(disp_mem_w_en),

                  .mem_data_out(mem_data_out),
                  .mem_rdy(disp_mem_rdy),
                  .mem_cplt(disp_mem_cplt)
                );

endmodule