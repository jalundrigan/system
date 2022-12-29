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

parameter CLK_SPEED = 50000000;
parameter BAUD_RATE = 115200;

logic [7:0] data_out;
logic serial_out_rdy;
logic serial_out_en;

logic [7:0] data_in;
logic serial_in_cplt;
logic serial_in_error;


serial_cntrl #(
                .CLK_SPEED(CLK_SPEED),
                .BAUD_RATE(BAUD_RATE)
             )
             SER
             (
                .clk(clk),
                .rst(~rst_n),

                .data_out(data_out),
                .serial_out_en(serial_out_en),
                .serial_out_rdy(serial_out_rdy),

                .data_in(data_in),
                .serial_in_cplt(serial_in_cplt),
                .serial_in_error(serial_in_error),

                .uart_rx(uart_rx),
                .uart_tx(uart_tx)
             );

enum logic [2:0] {
                    COMMAND, 
                    WRITE_MEM, 
                    WRITE_SERIAL_ACK, 
                    READ_MEM_1,
                    READ_MEM_2, 
                    WRITE_SERIAL_DATA_1,
                    WRITE_SERIAL_DATA_2
                 } state;

enum logic [3:0] {
                    FIRST_BYTE, 
                    BYTE_ADDRESS_W_1, 
                    BYTE_ADDRESS_W_2, 
                    BYTE_ADDRESS_W_3,
                    BYTE_DATA_W_1, 
                    BYTE_DATA_W_2,
                    BYTE_ADDRESS_R_1,
                    BYTE_ADDRESS_R_2,
                    BYTE_ADDRESS_R_3
                 } cmd_state;


logic [15:0] read_buff;

always_ff @(posedge clk or negedge rst_n)
begin
   if(rst_n == 1'b0)
   begin
      seg_val <= 24'hFFFF69;
      led <= 4'b0000;
      serial_out_en <= 1'b0;
      mem_w_en <= 1'b0;
      mem_r_en <= 1'b0;
      state <= COMMAND;
      cmd_state <= FIRST_BYTE;
   end
   else
   begin

      if(state == COMMAND)
      begin
         serial_out_en <= 1'b0;

         if(serial_in_error == 1'b1)
         begin
            led <= 4'b0001;
         end
         else
         if(serial_in_cplt == 1'b1)
         begin

            if(cmd_state == FIRST_BYTE)
            begin
               if(data_in == 8'b0)
               begin
                  // WRITE command received
                  cmd_state <= BYTE_ADDRESS_W_1;
               end
               else
               if(data_in == 8'b1)
               begin
                  // READ command received
                  cmd_state <= BYTE_ADDRESS_R_1;
               end
               else
               begin
                  led <= 4'b0010;
               end
            end
            // Write serial in
            else
            if(cmd_state == BYTE_ADDRESS_W_1)
            begin
               mem_addr[7:0] <= data_in;
               cmd_state <= BYTE_ADDRESS_W_2;
            end
            else
            if(cmd_state == BYTE_ADDRESS_W_2)
            begin
               mem_addr[15:8] <= data_in;
               cmd_state <= BYTE_ADDRESS_W_3;
            end
            else
            if(cmd_state == BYTE_ADDRESS_W_3)
            begin
               mem_addr[23:16] <= data_in;
               cmd_state <= BYTE_DATA_W_1;
               seg_val <= mem_addr;
            end
            else
            if(cmd_state == BYTE_DATA_W_1)
            begin
               mem_data_in[7:0] <= data_in;
               cmd_state <= BYTE_DATA_W_2;
            end
            else
            if(cmd_state == BYTE_DATA_W_2)
            begin
               mem_data_in[15:8] <= data_in;
               cmd_state <= FIRST_BYTE;
               state <= WRITE_MEM;
            end
            // Read serial in
            else
            if(cmd_state == BYTE_ADDRESS_R_1)
            begin
               mem_addr[7:0] <= data_in;
               cmd_state <= BYTE_ADDRESS_R_2;
            end
            else
            if(cmd_state == BYTE_ADDRESS_R_2)
            begin
               mem_addr[15:8] <= data_in;
               cmd_state <= BYTE_ADDRESS_R_3;
            end
            else
            if(cmd_state == BYTE_ADDRESS_R_3)
            begin
               mem_addr[23:16] <= data_in;
               cmd_state <= FIRST_BYTE;
               state <= READ_MEM_1;
               seg_val <= mem_addr;
            end
         end
      end
      // Write action
      else
      if(state == WRITE_MEM)
      begin
         if(mem_rdy == 1'b1)
         begin
            mem_w_en <= 1'b1;
            state <= WRITE_SERIAL_ACK;
         end
      end
      else
      if(state == WRITE_SERIAL_ACK)
      begin
         mem_w_en <= 1'b0;

         if(serial_out_rdy == 1'b1)
         begin
            data_out <= 8'd69;
            serial_out_en <= 1'b1;
            state <= COMMAND;
         end
      end
      // Read action
      else
      if(state == READ_MEM_1)
      begin
         if(mem_rdy == 1'b1)
         begin
            mem_r_en <= 1'b1;
            state <= READ_MEM_2;
         end
      end
      else
      if(state == READ_MEM_2)
      begin
         mem_r_en <= 1'b0;

         if(mem_cplt == 1'b1)
         begin
            read_buff <= mem_data_out;
            state <= WRITE_SERIAL_DATA_1;
         end
      end
      else
      if(state == WRITE_SERIAL_DATA_1)
      begin
         if(serial_out_en == 1'b1)
         begin
            serial_out_en <= 1'b0;
            state <= WRITE_SERIAL_DATA_2;
         end
         else
         if(serial_out_rdy == 1'b1)
         begin
            data_out <= read_buff[7:0];
            serial_out_en <= 1'b1;
         end
      end
      else
      if(state == WRITE_SERIAL_DATA_2)
      begin
         if(serial_out_rdy == 1'b1)
         begin
            data_out <= read_buff[15:8];
            serial_out_en <= 1'b1;
            state <= COMMAND;
         end
      end

   end

end

endmodule