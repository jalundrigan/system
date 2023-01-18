module cpu
        #(
            parameter MEM_ADDR_WIDTH,
            parameter REG_ADDR_WIDTH,
            parameter DATA_WIDTH,
            parameter REG_FILE_SIZE
        )
        (
            input logic clk,
            input logic rst,

            /*
                Memory
            */
            output logic[MEM_ADDR_WIDTH-1:0] mem_addr,
            output logic[DATA_WIDTH-1:0] mem_data_in,
            output logic mem_r_en,
            output logic mem_w_en,

            input logic[DATA_WIDTH-1:0] mem_data_out,
            input logic mem_rdy,
            input logic mem_cplt

`ifdef DISPLAY_PC
            ,
            output logic[MEM_ADDR_WIDTH-1:0] pc
`endif
        );

logic[REG_ADDR_WIDTH-1:0] reg_r_addr_1;
logic[REG_ADDR_WIDTH-1:0] reg_r_addr_2;
logic[REG_ADDR_WIDTH-1:0] reg_w_addr;
logic[DATA_WIDTH-1:0] reg_w_data;
logic reg_w_en;

logic[DATA_WIDTH-1:0] reg_r_data_1;
logic[DATA_WIDTH-1:0] reg_r_data_2;

core    #(
            .MEM_ADDR_WIDTH(MEM_ADDR_WIDTH),
            .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
            .DATA_WIDTH(DATA_WIDTH)
        )
        CORE
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

            .reg_r_addr_1(reg_r_addr_1),
            .reg_r_addr_2(reg_r_addr_2),
            .reg_w_addr(reg_w_addr),
            .reg_w_data(reg_w_data),
            .reg_w_en(reg_w_en),

            .reg_r_data_1(reg_r_data_1),
            .reg_r_data_2(reg_r_data_2)

`ifdef DISPLAY_PC
            ,
            .pc_out(pc)
`endif
        );


reg_file    #(
                .ADDR_WIDTH(REG_ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH),
                .REG_FILE_SIZE(REG_FILE_SIZE)
            )
            REG 
            (
                .clk(clk),
                .rst(rst),
                .reg_r_addr_1(reg_r_addr_1),
                .reg_r_addr_2(reg_r_addr_2),
                .reg_w_addr(reg_w_addr),
                .reg_w_data(reg_w_data),
                .reg_w_en(reg_w_en),

                .reg_r_data_1(reg_r_data_1),
                .reg_r_data_2(reg_r_data_2)
            );

endmodule