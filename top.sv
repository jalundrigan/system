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
   output logic uart_tx
);

parameter MEM_ADDR_WIDTH = 24;
parameter DATA_WIDTH = 16;
parameter REG_ADDR_WIDTH = 4;
parameter REG_FILE_SIZE = 16;

logic rst;
assign rst = ~rst_n;

// Input to memory controller
logic[MEM_ADDR_WIDTH-1:0] mem_addr;
logic[DATA_WIDTH-1:0] mem_data_in;
logic mem_r_en;
logic mem_w_en;

// Output from memory controller
logic mem_rdy;
logic mem_cplt;
logic[DATA_WIDTH-1:0] mem_data_out;

// MUXed memory controller input from CPU
logic[MEM_ADDR_WIDTH-1:0] cpu_mem_addr;
logic[DATA_WIDTH-1:0] cpu_mem_data_in;
logic cpu_mem_r_en;
logic cpu_mem_w_en;

// MUXed memory controller input from INIT
logic[MEM_ADDR_WIDTH-1:0] init_mem_addr;
logic[DATA_WIDTH-1:0] init_mem_data_in;
logic init_mem_r_en;
logic init_mem_w_en;


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
               .mem_rdy(mem_rdy),
               .mem_cplt(mem_cplt),

               .serial_data_out(serial_data_out),
               .serial_out_en(serial_out_en),
               .led(led),
               .mem_w_en(init_mem_w_en),
               .mem_r_en(init_mem_r_en),
               .mem_addr(init_mem_addr),
               .mem_data_in(init_mem_data_in)
            );


/*
   CPU
*/
cpu  #(
         .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
         .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
         .DATA_WIDTH(DATA_WIDTH),
         .REG_FILE_SIZE(REG_FILE_SIZE)
      )
      CPU
      (
         .clk(clk),
         .rst(rst),

         .mem_addr(cpu_mem_addr),
         .mem_data_in(cpu_mem_data_in),
         .mem_r_en(cpu_mem_r_en),
         .mem_w_en(cpu_mem_w_en),

         .mem_data_out(mem_data_out),
         .mem_rdy(mem_rdy),
         .mem_cplt(mem_cplt)
      );


assign mem_addr = init_mem_addr;
assign mem_data_in = init_mem_data_in;
assign mem_r_en = init_mem_r_en;
assign mem_w_en = init_mem_w_en;

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

                .mem_addr(mem_addr),
                .mem_data_in(mem_data_in),
                .mem_r_en(mem_r_en),
                .mem_w_en(mem_w_en),

                .mem_rdy(mem_rdy),
                .mem_cplt(mem_cplt),
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
                .dq(sdram_dq),

                .seg_sel(seg_sel),
                .seg_data(seg_data)
            );

endmodule