module mem_driver
        #(
		    parameter ADDR_WIDTH,
		    parameter DATA_WIDTH
	    )
        (
            input logic clk,
            input logic rst,

            input logic[ADDR_WIDTH-1:0] mem_addr,
            input logic[DATA_WIDTH-1:0] mem_data_in,
            input logic mem_r_en,
            input logic mem_w_en,
            
            output logic[DATA_WIDTH-1:0] mem_data_out,
            output logic mem_rdy,
            output logic mem_cplt,

            output logic cke,
            output logic cs_n,
            output logic ras_n,
            output logic cas_n,
            output logic we_n,

            output logic [12:0] a,
            output logic [1:0] bs,

            inout [15:0] dq,

            output logic ldqm,
            output logic udqm
        );

enum logic [3:0] {
                    INIT_WAIT_200, 
                    INIT_PRECHARGE, 
                    INIT_MODE_SET, 
                    INIT_AUTO_REFRESH,
                    IDLE, 
                    BANK_ACTIVE,
                    MEM_WRITE,
                    MEM_READ,
                    AUTO_PRECHARGE_WAIT,
                    AUTO_REFRESH_1,
                    AUTO_REFRESH_2
                 } state, next_state;

parameter clk_freq = 50000000;

logic [15:0] timer;
logic [4:0] refresh_counter;

logic[ADDR_WIDTH-1:0] mem_addr_buf;
logic[DATA_WIDTH-1:0] mem_data_in_buf;
logic mem_r_en_buf;
logic mem_w_en_buf;
logic write_bus;

logic [9:0] auto_refresh_trigger;
logic auto_refresh_reset;

logic buffered_mem_request;

logic init;

assign dq = (write_bus == 1'b1) ? mem_data_in_buf : ($bits(dq))'('bz);

always_ff @(posedge clk or posedge rst)
begin

    if(rst == 1'b1)
    begin
        state <= INIT_WAIT_200;
        timer <= 16'b0;
        refresh_counter <= 5'b0;

        cke <= 1'b1;
        cs_n <= 1'b0;
        ras_n <= 1'b1;
        cas_n <= 1'b1;
        we_n <= 1'b1;
        ldqm <= 1'b1;
        udqm <= 1'b1;
        bs <= 2'b00;

        mem_rdy <= 1'b0;
        mem_cplt <= 1'b0;
        write_bus <= 1'b0;
        auto_refresh_reset <= 1'b0;
        buffered_mem_request <= 1'b0;
        init <= 1'b0;

    end
    else
    begin

        if(state == INIT_WAIT_200)
        begin
            timer <= timer + 16'b1;
            if(timer == 16'd10000)
            begin
                // 200us
                state <= INIT_PRECHARGE;
                timer <= 16'b0;
                ldqm <= 1'b0;
                udqm <= 1'b0;
            end
        end
        else
        if(state == INIT_PRECHARGE)
        begin
            // precharge all banks
            ras_n <= 1'b0;
            cas_n <= 1'b1;
            we_n <= 1'b0;
            a[10] <= 1'b1;

            if(timer == 16'd0)
            begin
                cs_n <= 1'b0;
            end
            else
            begin
                cs_n <= 1'b1;
            end

            timer <= timer + 16'b1;
            if(timer == 16'd1)
            begin
                // minimum t_rp (15ns) -- may need to unset cs_n
                state <= INIT_MODE_SET;
                timer <= 16'b0;
            end
        end
        else
        if(state == INIT_MODE_SET)
        begin

            ras_n <= 1'b0;
            cas_n <= 1'b0;
            we_n <= 1'b0;

            if(timer == 16'd0)
            begin
                // mode register set command
                cs_n <= 1'b0;
            end
            else
            begin
                cs_n <= 1'b1;
            end

            // burst length = 1
            a[2:0] <= 3'b000;
            // sequential
            a[3] <= 1'b0;
            // CAS latency = 3
            a[6:4] <= 3'b011;
            // reserved
            a[8:7] <= 2'b00;
            // single write
            a[9] <= 1'b0;
            
            // reserved
            a[12:10] <= 3'b0;
            bs[1:0] <= 2'b00;

            timer <= timer + 16'b1;
            if(timer == 16'd5)
            begin
                // minimum t_rsc (2 clock cycles)
                state <= INIT_AUTO_REFRESH;
                timer <= 16'b0;
            end
        end
        else
        if(state == INIT_AUTO_REFRESH)
        begin
            if(refresh_counter == 5'd7)
            begin
                state <= IDLE;
                mem_rdy <= 1'b1;
            end
            else
            begin
                state <= AUTO_REFRESH_1;
                next_state <= INIT_AUTO_REFRESH;
                refresh_counter <= refresh_counter + 5'b1;
            end
        end
        else
        if(state == IDLE)
        begin
            init <= 1'b1;
            cs_n <= 1'b0;
            ras_n <= 1'b1;
            cas_n <= 1'b1;
            we_n <= 1'b1;
            
            timer <= 16'b0;
            mem_cplt <= 1'b0;
            mem_rdy <= 1'b1;
            buffered_mem_request <= 1'b0;
            
            if(auto_refresh_trigger >= 10'd390)
            begin
                auto_refresh_reset <= 1'b1;
                mem_rdy <= 1'b0;
                state <= AUTO_REFRESH_1;
                next_state <= IDLE;

                // should we also check that either mem_rdy or mem_cplt are set? so we don't buffer a read or write that was not meant to be registered
                if((mem_r_en == 1'b1 || mem_w_en == 1'b1) && mem_rdy == 1'b1)
                begin
                    buffered_mem_request <= 1'b1;
                    mem_addr_buf <= mem_addr;
                    mem_data_in_buf <= mem_data_in;
                    mem_r_en_buf <= mem_r_en;
                    mem_w_en_buf <= mem_w_en;
                end
            end
            else
            if(mem_r_en == 1'b1 || mem_w_en == 1'b1 || buffered_mem_request == 1'b1)
            begin
                state <= BANK_ACTIVE;
                mem_rdy <= 1'b0;

                // bank active command
                cs_n <= 1'b0;
                ras_n <= 1'b0;
                cas_n <= 1'b1;
                we_n <= 1'b1;

                if(buffered_mem_request == 1'b1)
                begin
                    // greatest 2 MSB refers to the bank
                    bs <= mem_addr_buf[ADDR_WIDTH-1:ADDR_WIDTH-2];
                    // next greatest 13 MSB refer to the row
                    a[12:0] <= mem_addr_buf[ADDR_WIDTH-3:ADDR_WIDTH-15];
                end
                else
                if(mem_r_en == 1'b1 || mem_w_en == 1'b1)
                begin
                    mem_addr_buf <= mem_addr;
                    mem_data_in_buf <= mem_data_in;
                    mem_r_en_buf <= mem_r_en;
                    mem_w_en_buf <= mem_w_en;

                    // greatest 2 MSB refers to the bank
                    bs <= mem_addr[ADDR_WIDTH-1:ADDR_WIDTH-2];
                    // next greatest 13 MSB refer to the row
                    a[12:0] <= mem_addr[ADDR_WIDTH-3:ADDR_WIDTH-15];
                end
            end
        end
        else 
        if(state == BANK_ACTIVE)
        begin
            cs_n <= 1'b1;

            // minimum t_rcd (15ns)
            if(mem_w_en_buf == 1'b1)
            begin
                state <= MEM_WRITE;
            end
            else
            if(mem_r_en_buf == 1'b1)
            begin
                state <= MEM_READ;
            end
        end
        else
        if(state == MEM_WRITE)
        begin
            // greatest 2 MSB refers to the bank
            bs <= mem_addr_buf[ADDR_WIDTH-1:ADDR_WIDTH-2];
            a[10] <= 1'b1;
            // least 9 MSB refer to the column
            a[8:0] <= mem_addr_buf[ADDR_WIDTH-16:ADDR_WIDTH-24];
            // shouldnt matter for these
            a[12:11] <= 2'b00;
            a[9] <= 1'b0;

            // write with auto precharge command
            ras_n <= 1'b1;
            cas_n <= 1'b0;
            we_n <= 1'b0;

            timer <= timer + 16'b1;
            if(timer == 16'd0)
            begin
                cs_n <= 1'b0;
                write_bus <= 1'b1;
            end
            else
            begin
                cs_n <= 1'b1;

                state <= AUTO_PRECHARGE_WAIT;
                timer <= 16'b0;
                write_bus <= 1'b0;
            end
        end
        else
        if(state == MEM_READ)
        begin
            // greatest 2 MSB refers to the bank
            bs <= mem_addr_buf[ADDR_WIDTH-1:ADDR_WIDTH-2];
            a[10] <= 1'b1;
            // least 9 MSB refer to the column
            a[8:0] <= mem_addr_buf[ADDR_WIDTH-16:ADDR_WIDTH-24];
            // shouldnt matter for these
            a[12:11] <= 2'b00;
            a[9] <= 1'b0;

            // read with auto precharge command
            ras_n <= 1'b1;
            cas_n <= 1'b0;
            we_n <= 1'b1;

            if(timer == 16'd0)
            begin
                cs_n <= 1'b0;
            end
            else
            begin
                cs_n <= 1'b1;
            end

            timer <= timer + 16'b1;
            // wait for CAS delay
            if(timer == 16'd4)
            begin
                mem_data_out <= dq;
                timer <= 16'b0;
                state <= AUTO_PRECHARGE_WAIT;
            end
        end
        else
        if(state == AUTO_PRECHARGE_WAIT)
        begin
            cs_n <= 1'b1;
            
            timer <= timer + 16'b1;
            if(timer == 16'd0)
            begin
                // minimum t_rp (15ns)
                state <= IDLE;
                timer <= 16'b0;
                mem_cplt <= 1'b1;
                mem_rdy <= 1'b1;
            end
        end
        else
        if(state == AUTO_REFRESH_1)
        begin
            // precharge all banks
            ras_n <= 1'b0;
            cas_n <= 1'b1;
            we_n <= 1'b0;
            a[10] <= 1'b1;

            if(timer == 16'd0)
            begin
                cs_n <= 1'b0;

                /*
                if((mem_r_en == 1'b1 || mem_w_en == 1'b1) && init == 1'b1 && buffered_mem_request == 1'b0)
                begin
                    buffered_mem_request <= 1'b1;
                    mem_addr_buf <= mem_addr;
                    mem_data_in_buf <= mem_data_in;
                    mem_r_en_buf <= mem_r_en;
                    mem_w_en_buf <= mem_w_en;
                end
                */
            end
            else
            begin
                cs_n <= 1'b1;
            end

            timer <= timer + 16'b1;
            if(timer == 16'd5)
            begin
                // minimum t_rp (like 15ns or something)
                state <= AUTO_REFRESH_2;
                timer <= 16'b0;
            end
        end
        else
        if(state == AUTO_REFRESH_2)
        begin
            // auto refresh
            ras_n <= 1'b0;
            cas_n <= 1'b0;
            we_n <= 1'b1;
            
            if(timer == 16'd0)
            begin
                cs_n <= 1'b0;
            end
            else
            begin
                cs_n <= 1'b1;
            end

            timer <= timer + 16'b1;
            if(timer == 16'd5)
            begin
                // minimum t_rc (like 60ns or something)
                state <= next_state;
                timer <= 16'b0;
                auto_refresh_reset <= 1'b0;
                if(next_state == IDLE && buffered_mem_request == 1'b0)
                begin
                    mem_rdy <= 1'b1;
                end
            end
        end

    end

end


// generate auto refresh cycles @ 64ms / 8K = 7.8125us
// 50000000Mhz * 7.8125us = 390 cycles
always_ff @(posedge clk or posedge rst)
begin

    if(rst == 1'b1)
    begin
        auto_refresh_trigger <= 10'b0;
    end
    else
    begin
        if(auto_refresh_reset == 1'b1)
        begin
            auto_refresh_trigger <= 10'b0;
        end
        else
        begin
            auto_refresh_trigger <= auto_refresh_trigger + 10'b1;
        end
    end

end

endmodule