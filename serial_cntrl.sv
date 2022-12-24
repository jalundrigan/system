module serial_cntrl
    #(
        parameter CLK_SPEED,
        parameter BAUD_RATE
	)
    (
        input logic clk,
        input logic rst,

        input logic [7:0] data_out,
        input logic serial_out_en,
        output logic serial_out_rdy,

        output logic [7:0] data_in,
        output logic serial_in_cplt,
        output logic serial_in_error,

        input logic uart_rx,
        output logic uart_tx
    );

parameter NUM_CLK = CLK_SPEED / BAUD_RATE; //434

enum logic [1:0] {
                    RX_IDLE, 
                    RX_START,
                    RX_DATA_IN,
                    RX_STOP
                 } rx_state;

enum logic [1:0] {
                    TX_IDLE, 
                    TX_START,
                    TX_DATA_OUT,
                    TX_STOP
                 } tx_state;

// TX signals
logic [15:0] tx_baud_counter;
logic tx_baud_full;
logic [3:0] tx_data_count;
logic [8:0] data_out_buf;


// RX signals
logic [15:0] rx_baud_counter;
logic rx_baud_half;
logic rx_baud_full;

logic [8:0] rx_data_in_buf;
logic rx_data_parity;
logic [3:0] rx_data_count;

assign data_in = rx_data_in_buf[7:0];
assign rx_data_parity = ^rx_data_in_buf;

logic uart_rx_buf;
logic uart_rx_buf_last;

// RX FSM
always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
    begin
        rx_state <= RX_IDLE;
        uart_rx_buf <= 1'b0;
        uart_rx_buf_last <= 1'b0;
        rx_data_count <= 4'b0;
        serial_in_error <= 1'b0;
        serial_in_cplt <= 1'b0;
    end
    else
    begin
        serial_in_error <= 1'b0;
        serial_in_cplt <= 1'b0;
        
        uart_rx_buf <= uart_rx;
        uart_rx_buf_last <= uart_rx_buf;

        if(rx_state == RX_IDLE)
        begin
            // Falling edge
            if(uart_rx_buf_last == 1'b1 && uart_rx_buf == 1'b0)
            begin
                rx_state <= RX_START;
            end
        end
        else 
        if(rx_state == RX_START)
        begin
            if(rx_baud_full == 1'b1)
            begin
                rx_state <= RX_DATA_IN;
            end
        end
        else
        if(rx_state == RX_DATA_IN)
        begin
            if(rx_baud_half == 1'b1)
            begin
                rx_data_in_buf[8] <= uart_rx_buf;
                for(int i = 7;i >= 0;i --)
                begin
                    rx_data_in_buf[i] <= rx_data_in_buf[i+1];
                end
            end 
            
            if(rx_baud_full == 1'b1)
            begin
                if(rx_data_count == 4'd8)
                begin
                    rx_state <= RX_STOP;
                    rx_data_count <= 4'b0;
                end
                else
                begin
                    rx_data_count <= rx_data_count + 4'b1;
                end
            end
        end
        else
        if(rx_state == RX_STOP)
        begin
            if(rx_baud_half == 1'b1)
            begin
                if(uart_rx_buf != 1'b1 || rx_data_parity == 1'b1)
                begin
                    serial_in_error <= 1'b1;
                end
                else
                begin
                    serial_in_cplt <= 1'b1;
                end

                rx_state <= RX_IDLE;
            end
        end

    end
end

// RX Timer
always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
    begin
        rx_baud_counter <= 16'b0;
        rx_baud_half <= 1'b0;
        rx_baud_full <= 1'b0;
    end
    else
    begin
        rx_baud_half <= 1'b0;
        rx_baud_full <= 1'b0;

        if(rx_state != RX_IDLE)
        begin
            if(rx_baud_counter < NUM_CLK)
            begin
                rx_baud_counter <= rx_baud_counter + 16'b1;
                if(rx_baud_counter == NUM_CLK / 2)
                begin
                    rx_baud_half <= 1'b1;
                end
            end
            else
            begin
                rx_baud_counter <= 16'b0;
                rx_baud_full <= 1'b1;
            end
        end
        else
        begin
            rx_baud_counter <= 16'b0;
        end
    end
end



/*
    ====================================
    ====================================
*/



// TX FSM
always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
    begin
        tx_state <= TX_IDLE;
        serial_out_rdy <= 1'b0;
        uart_tx <= 1'b1;
        tx_data_count <= 4'b0;
    end
    else
    begin

        if(tx_state == TX_IDLE)
        begin
            if(serial_out_en == 1'b1)
            begin
                tx_state <= TX_START;
                serial_out_rdy <= 1'b0;
                data_out_buf[7:0] <= data_out;
                data_out_buf[8] <= ^data_out;
                uart_tx <= 1'b0;
            end
            else
            begin
                serial_out_rdy <= 1'b1;
                uart_tx <= 1'b1;
            end
        end
        else 
        if(tx_state == TX_START)
        begin
            if(tx_baud_full == 1'b1)
            begin
                tx_state <= TX_DATA_OUT;
            end
        end
        else
        if(tx_state == TX_DATA_OUT)
        begin
            uart_tx <= data_out_buf[0];
            
            if(tx_baud_full == 1'b1)
            begin
                if(tx_data_count == 4'd8)
                begin
                    tx_state <= TX_STOP;
                    tx_data_count <= 4'b0;
                end
                else
                begin
                    tx_data_count <= tx_data_count + 4'b1;

                    for(int i = 7;i >= 0;i --)
                    begin
                        data_out_buf[i] <= data_out_buf[i+1];
                    end
                end
            end
        end
        else
        if(tx_state == TX_STOP)
        begin
            uart_tx <= 1'b1;

            if(tx_baud_full == 1'b1)
            begin
                tx_state <= TX_IDLE;
                serial_out_rdy <= 1'b1;
            end
        end

    end
end

// TX Timer
always_ff @(posedge clk or posedge rst)
begin
    if(rst == 1'b1)
    begin
        tx_baud_counter <= 16'b0;
        tx_baud_full <= 1'b0;
    end
    else
    begin
        tx_baud_full <= 1'b0;

        if(tx_state != TX_IDLE)
        begin
            if(tx_baud_counter < NUM_CLK)
            begin
                tx_baud_counter <= tx_baud_counter + 16'b1;
            end
            else
            begin
                tx_baud_counter <= 16'b0;
                tx_baud_full <= 1'b1;
            end
        end
        else
        begin
            tx_baud_counter <= 16'b0;
        end
    end
end

endmodule