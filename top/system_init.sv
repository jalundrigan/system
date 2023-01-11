module system_init
      #(
         parameter ADDR_WIDTH,
         parameter DATA_WIDTH
      )
      (
         input logic clk,
         input logic rst_n,

         input logic[DATA_WIDTH-1:0] mem_data_out,
         input logic serial_in_error,
         input logic serial_in_cplt,
         input logic[7:0] serial_data_in,
         input logic serial_out_rdy,
         input logic mem_rdy,
         input logic mem_cplt,

         output logic[7:0] serial_data_out,
         output logic serial_out_en,
         output logic[3:0] led,
         output logic mem_w_en,
         output logic mem_r_en,
         output logic[ADDR_WIDTH-1:0] mem_addr,
         output logic[DATA_WIDTH-1:0] mem_data_in,

         output logic cpu_enable
      );


enum logic [2:0] {
                    COMMAND, 
                    WRITE_MEM, 
                    WRITE_SERIAL_ACK, 
                    READ_MEM_1,
                    READ_MEM_2, 
                    WRITE_SERIAL_DATA_1,
                    WRITE_SERIAL_DATA_2,
                    COMPLETE_INIT
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
      led <= 4'b0000;
      serial_out_en <= 1'b0;
      mem_w_en <= 1'b0;
      mem_r_en <= 1'b0;
      state <= COMMAND;
      cmd_state <= FIRST_BYTE;
      cpu_enable <= 1'b0;
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
               if(serial_data_in == 8'd0)
               begin
                  // WRITE command received
                  cmd_state <= BYTE_ADDRESS_W_1;
               end
               else
               if(serial_data_in == 8'd1)
               begin
                  // READ command received
                  cmd_state <= BYTE_ADDRESS_R_1;
               end
               else
               if(serial_data_in == 8'd2)
               begin
                  state <= COMPLETE_INIT;
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
               mem_addr[7:0] <= serial_data_in;
               cmd_state <= BYTE_ADDRESS_W_2;
            end
            else
            if(cmd_state == BYTE_ADDRESS_W_2)
            begin
               mem_addr[15:8] <= serial_data_in;
               cmd_state <= BYTE_ADDRESS_W_3;
            end
            else
            if(cmd_state == BYTE_ADDRESS_W_3)
            begin
               mem_addr[23:16] <= serial_data_in;
               cmd_state <= BYTE_DATA_W_1;
            end
            else
            if(cmd_state == BYTE_DATA_W_1)
            begin
               mem_data_in[7:0] <= serial_data_in;
               cmd_state <= BYTE_DATA_W_2;
            end
            else
            if(cmd_state == BYTE_DATA_W_2)
            begin
               mem_data_in[15:8] <= serial_data_in;
               cmd_state <= FIRST_BYTE;
               state <= WRITE_MEM;
            end
            // Read serial in
            else
            if(cmd_state == BYTE_ADDRESS_R_1)
            begin
               mem_addr[7:0] <= serial_data_in;
               cmd_state <= BYTE_ADDRESS_R_2;
            end
            else
            if(cmd_state == BYTE_ADDRESS_R_2)
            begin
               mem_addr[15:8] <= serial_data_in;
               cmd_state <= BYTE_ADDRESS_R_3;
            end
            else
            if(cmd_state == BYTE_ADDRESS_R_3)
            begin
               mem_addr[23:16] <= serial_data_in;
               cmd_state <= FIRST_BYTE;
               state <= READ_MEM_1;
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
            serial_data_out <= 8'd69;
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
            serial_data_out <= read_buff[7:0];
            serial_out_en <= 1'b1;
         end
      end
      else
      if(state == WRITE_SERIAL_DATA_2)
      begin
         if(serial_out_rdy == 1'b1)
         begin
            serial_data_out <= read_buff[15:8];
            serial_out_en <= 1'b1;
            state <= COMMAND;
         end
      end
      else
      if(state == COMPLETE_INIT)
      begin
         cpu_enable <= 1'b1;
      end

   end

end

endmodule