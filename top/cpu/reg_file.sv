module reg_file
    #(
		parameter ADDR_WIDTH,
		parameter DATA_WIDTH,
		parameter REG_FILE_SIZE
	)

	(
		input logic clk,
		input logic rst,

		input logic[ADDR_WIDTH-1:0] reg_r_addr_1,
		input logic[ADDR_WIDTH-1:0] reg_r_addr_2,

        input logic[ADDR_WIDTH-1:0] reg_w_addr,
        input logic[DATA_WIDTH-1:0] reg_w_data,
		input logic reg_w_en,
		
		output logic[DATA_WIDTH-1:0] reg_r_data_1,
        output logic[DATA_WIDTH-1:0] reg_r_data_2
	);

logic[REG_FILE_SIZE-1:0] reg_file[DATA_WIDTH-1:0];


assign reg_r_data_1 = reg_file[reg_r_addr_1];
assign reg_r_data_2 = reg_file[reg_r_addr_2];

always_ff @(posedge clk or posedge rst)
begin

	if(rst == 1'b1)
	begin
		for(int i = 0;i < REG_FILE_SIZE;i ++)
		begin
			reg_file[i] <= 16'b0;
		end
	end
	else
    if(reg_w_en == 1'b1)
    begin
        reg_file[reg_w_addr] <= reg_w_data;
    end

end


endmodule

