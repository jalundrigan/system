module alu    
	#(
		parameter DATA_WIDTH,
		parameter OPCODE_WIDTH
	)
	
	(
		input logic clk,
		input logic rst,
		input logic[DATA_WIDTH-1:0] op_a,
		input logic[DATA_WIDTH-1:0] op_b,
        input logic[OPCODE_WIDTH-1:0] opcode,
		input logic alu_active,

		output logic[DATA_WIDTH-1:0] result,
		output logic equal,
		output logic less,
		output logic greater
	);


logic[7:0] flag_reg;

assign equal = flag_reg[0];
assign less = flag_reg[1];
assign greater = flag_reg[2];

always_comb
begin

	result <= ($bits(result))'('b0); // Can be dont care;

	if(opcode == 4'b0000)
	begin
		result <= op_a + op_b;
	end
	else
	if(opcode == 4'b0001)
	begin
		result <= op_a - op_b;
	end
	else
	if(opcode == 4'b0010)
	begin
		result <= op_a * op_b;
	end
	else
	if(opcode == 4'b0011)
	begin
		result <= op_a & op_b;
	end
	else
	if(opcode == 4'b0100)
	begin
		result <= op_a | op_b;
	end
	else
	if(opcode == 4'b0101)
	begin
		result <= op_a ^ op_b;
	end
	else
	if(opcode == 4'b0110)
	begin
		result <= ~op_a;
	end
	else
	if(opcode == 4'b0111)
	begin
		result <= (~op_a) + (DATA_WIDTH)'('b1);
	end
end


always_ff @(posedge clk or posedge rst)
begin

    if(rst == 1'b1)
    begin
		flag_reg <= 8'b0;
	end
	else
	begin

		flag_reg <= 8'b0; // Can be dont care;

		if(alu_active == 1'b1)
		begin
			if(opcode == 4'b1000)
			begin
				if(op_a == op_b)
				begin
					flag_reg[0] <= 1'b1;
					flag_reg[1] <= 1'b0;
					flag_reg[2] <= 1'b0;
				end
				else
				if(op_a < op_b)
				begin
					flag_reg[0] <= 1'b0;
					flag_reg[1] <= 1'b1;
					flag_reg[2] <= 1'b0;
				end
				else
				if(op_a > op_b)
				begin
					flag_reg[0] <= 1'b0;
					flag_reg[1] <= 1'b0;
					flag_reg[2] <= 1'b1;
				end
			end
		end
	end
end

endmodule