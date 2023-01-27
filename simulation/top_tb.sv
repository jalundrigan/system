`include "assembler_util.sv"

module top_tb;

parameter MEM_ADDR_WIDTH = 16;
parameter REG_ADDR_WIDTH = 4;
parameter DATA_WIDTH = 16;
parameter MEM_SIZE = 65536;
parameter REG_FILE_SIZE = 16;

logic clk;
logic rst;

logic[MEM_SIZE-1:0][DATA_WIDTH-1:0] sym_mem;

logic[3:0] led; // Don't read
logic sdram_clk; // Don't read
logic sdram_cke; // Don't read
logic sdram_cs_n; // Don't read
logic sdram_we_n; // Don't read
logic sdram_cas_n; // Don't read
logic sdram_ras_n; // Don't read
logic[1:0] sdram_dqm; // Don't read
logic[1:0] sdram_ba; // Don't read
logic[12:0] sdram_addr; // Don't read
wire [15:0] sdram_dq; // Don't read
    
logic [5:0] seg_sel; // Don't read
logic [7:0] seg_data; // Don't read

logic uart_rx; // Drive to 1
logic uart_tx; // Don't read

logic cpu_enable;

top TOP
	(
	.clk(clk),
	.rst_n(~rst),

	.led(led),
	.sdram_clk(sdram_clk),     //sdram clock
	.sdram_cke(sdram_cke),     //sdram clock enable
	.sdram_cs_n(sdram_cs_n),    //sdram chip select
	.sdram_we_n(sdram_we_n),    //sdram write enable
	.sdram_cas_n(sdram_cas_n),   //sdram column address strobe
	.sdram_ras_n(sdram_ras_n),   //sdram row address strobe
	.sdram_dqm(sdram_dqm),     //sdram data enable 
	.sdram_ba(sdram_ba),      //sdram bank address
	.sdram_addr(sdram_addr),    //sdram address
	.sdram_dq(sdram_dq),       //sdram data
		
	.seg_sel(seg_sel),
	.seg_data(seg_data),

	.uart_rx(uart_rx),
	.uart_tx(uart_tx),

	.cpu_enable(cpu_enable)
	);

assign uart_rx = 1'b1;

always 
begin
    clk = ~clk; 
    #1;
end


initial
begin
    clk <= 1'b0;
    rst <= 1'b1;
    #2;
    rst <= 1'b0;
end


typedef struct
{
	string cmd;
	int op_1;
	int op_2;
	int addr;
} instr_list_t;

instr_list_t instr_list[MEM_SIZE];
logic[MEM_SIZE-1:0][DATA_WIDTH-1:0] mock_mem;
logic[REG_FILE_SIZE-1:0][DATA_WIDTH-1:0] mock_reg;

initial
begin

	int file;
	string line;
	string cmd;
	string arg_1;
	string arg_2;
	string arg_3;
	int op_1;
	int op_2;
	int status;
	int i = 0;

	$display("==========\nStart of file read and mem init\n==========\n");

	file = $fopen("../assembler/tester.jasm", "r");

	if(file == 0)
	begin
		$display("Error opening file");
		$stop;
	end

	while(!$feof(file))
	begin
		void'($fgets(line, file));
		$display("%s", line);

		if(line.len() == 0)
		begin
			continue;
		end

		line = strip_leading_whitespace(line);

		if(is_comment(line) == 1)
		begin
			continue;
		end

		cmd = get_cmd(line, line);

		line = strip_all_whitespace(line);

		if(cmd.len() == 0 || line.len() == 0)
		begin
			$display("Syntax error @line %d", i);
			$stop;
		end

		op_1 = 0;
		op_2 = 0;

		if(cmd == "LLI")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = const_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {4'b0110, 8'(op_2), 4'(op_1)};
		end
		else
		if(cmd == "LUI")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = const_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {4'b0111, 8'(op_2), 4'(op_1)};
		end
		else
		if(cmd == "LDD")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = const_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b000, 9'(op_2), 4'(op_1)};
		end
		else
		if(cmd == "LDN")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = reg_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b10000, 4'(op_2), 4'(op_1)};
		end
		else
		if(cmd == "STD")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = const_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = reg_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b010, 9'(op_1), 4'(op_2)};
		end
		else
		if(cmd == "STI")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = reg_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b10001, 4'(op_1), 4'(op_2)};
		end
		else
		if(cmd == "J")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = const_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b001, 13'(op_1)};
		end
		else
		if(cmd == "BEQ")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = const_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {5'b10000, 11'(op_1)};
		end
		else
		if(cmd == "BNE")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = const_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {5'b10001, 11'(op_1)};
		end
		else
		if(cmd == "BLT")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = const_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {5'b10010, 11'(op_1)};
		end
		else
		if(cmd == "BGT")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = const_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {5'b10011, 11'(op_1)};
		end
		else
		if(cmd == "ADD")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = reg_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00000, 4'(op_2), 4'(op_1)};
		end
		else
		if(cmd == "SUB")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = reg_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00001, 4'(op_2), 4'(op_1)};
		end
		else
		if(cmd == "MUL")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = reg_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00010, 4'(op_2), 4'(op_1)};
		end
		else
		if(cmd == "AND")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = reg_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00011, 4'(op_2), 4'(op_1)};
		end
		else
		if(cmd == "OR")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = reg_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00100, 4'(op_2), 4'(op_1)};
		end
		else
		if(cmd == "XOR")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = reg_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00101, 4'(op_2), 4'(op_1)};
		end
		else
		if(cmd == "CMP1")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00110, 4'b0, 4'(op_1)};
		end
		else
		if(cmd == "CMP2")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00111, 4'b0, 4'(op_1)};
		end
		else
		if(cmd == "CPP")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = reg_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b01000, 4'(op_2), 4'(op_1)};
		end
		else
		if(cmd == "MOV")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = reg_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b10010, 4'(op_2), 4'(op_1)};
		end
		else
		if(cmd == "ADDI")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = const_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b101, 9'(op_2), 4'(op_1)};
		end
		else
		if(cmd == "SUBI")
		begin
			arg_1 = get_next_arg(line, line);
			op_1 = reg_decode(arg_1, status);
			if(status == 0)
			begin
				$display("Arg1 Syntax error @line %d", i);
				$stop;
			end

			arg_2 = get_next_arg(line, line);
			op_2 = const_decode(arg_2, status);
			if(status == 0)
			begin
				$display("Arg2 Syntax error @line %d", i);
				$stop;
			end

			sym_mem[i][DATA_WIDTH-1:0] = {3'b110, 9'(op_2), 4'(op_1)};
		end
		else
		begin
			$display("Unknown instruction @line %d", i);
			$stop;
		end
			
		$display("%x", sym_mem[i]);

		instr_list[i].cmd = cmd;
		instr_list[i].op_1 = op_1;
		instr_list[i].op_2 = op_2;
		instr_list[i].addr = i;

		i += 1;

	end

	$fclose(file);

	while(i < MEM_SIZE)
	begin
		sym_mem[i][DATA_WIDTH-1:0] = i;
		i += 1;
	end

	for(i = 0;i < MEM_SIZE;i ++)
	begin
		mock_mem[i] = sym_mem[i];
	end

	for(i = 0;i < REG_FILE_SIZE;i ++)
	begin
		mock_reg[i] = 0;
	end

	$display("==========\nEnd of file read and mem init\n==========\n");

end

int instr_index;
instr_list_t pipe_buf[3];
instr_list_t test_buf;
int pending;
int pending_index;
int next_check;
int compare_flags[8];

initial
begin

	instr_index = 0;
	pending = 0;
	pending_index = 0;
	next_check = 0;

	for(int i = 0;i < 3;i ++)
	begin
		pipe_buf[i].cmd = "";
		pipe_buf[i].op_1 = 0;
		pipe_buf[i].op_2 = 0;
	end

	for(int i = 0;i < 7; i ++)
	begin
		compare_flags[i] = 0;
	end

	test_buf.cmd = "";
	test_buf.op_1 = 0;
	test_buf.op_2 = 0;

end


function int mem_compare();

	int ret = 1;

	for(int i = 0;i < MEM_SIZE;i ++)
	begin
		if(i == 256)
		begin
			if(mock_mem[i] != TOP.MEM_CTRL.seg_val[15:0])
			begin
				$display("mock != mem @address %d: %x != %x", i, mock_mem[i], TOP.MEM_CTRL.seg_val[15:0]);
				ret = 0;
			end
		end
		else
		begin
			if(mock_mem[i] != sym_mem[i])
			begin
				$display("mock != mem @address %d: %x != %x", i, mock_mem[i], sym_mem[i]);
				ret = 0;
			end
		end
	end

	for(int i = 0;i < REG_FILE_SIZE;i ++)
	begin
		if(mock_reg[i] != TOP.CPU.REG.reg_file[i])
		begin
			$display("mock != reg @address %d: %x != %x", i, mock_reg[i], TOP.CPU.REG.reg_file[i]);
			ret = 0;
		end
	end

	/*
	if(instr_index != PROC.pc)
	begin
		$display("mock != PC: %x != %x", instr_index, PROC.pc);
		ret = 0;
	end
	*/

	return ret;

endfunction


always @(posedge clk)
begin

	if(next_check == 1 || (pending == 1 && TOP.CPU.CORE.stage_2_buf[TOP.CPU.CORE.s_2_valid] == 1'b0))
	begin
		next_check = 0;

		if(TOP.CPU.CORE.stage_2_buf[TOP.CPU.CORE.s_2_valid] == 1'b0)
		begin
			test_buf = pipe_buf[2];
			pending = 0;
		end

		$display("%s\n", test_buf.cmd);

		if(test_buf.cmd == "LLI")
		begin
			mock_reg[test_buf.op_1] = {mock_reg[test_buf.op_1][15:8], 8'(test_buf.op_2)};
		end
		else
		if(test_buf.cmd == "LUI")
		begin
			mock_reg[test_buf.op_1] = {8'(test_buf.op_2), mock_reg[test_buf.op_1][7:0]};
		end		
		else
		if(test_buf.cmd == "LDD")
		begin
			mock_reg[test_buf.op_1] = mock_mem[test_buf.op_2];
		end
		else
		if(test_buf.cmd == "LDN")
		begin
			mock_reg[test_buf.op_1] = mock_mem[mock_reg[test_buf.op_2]];
		end
		else
		if(test_buf.cmd == "STD")
		begin
			mock_mem[test_buf.op_1] = mock_reg[test_buf.op_2];
		end
		else
		if(test_buf.cmd == "STI")
		begin
			mock_mem[mock_reg[test_buf.op_1]] = mock_reg[test_buf.op_2];
		end
		else
		if(test_buf.cmd == "J")
		begin
			instr_index = test_buf.addr + test_buf.op_1;
		end
		else
		if(test_buf.cmd == "BEQ")
		begin
			if(compare_flags[0] == 1)
			begin
				instr_index = test_buf.addr + test_buf.op_1;
			end
		end
		else
		if(test_buf.cmd == "BNE")
		begin
			if(compare_flags[0] == 0)
			begin
				instr_index = test_buf.addr + test_buf.op_1;
			end
		end
		else
		if(test_buf.cmd == "BLT")
		begin
			if(compare_flags[1] == 1)
			begin
				instr_index = test_buf.addr + test_buf.op_1;
			end
		end
		else
		if(test_buf.cmd == "BGT")
		begin
			if(compare_flags[2] == 1)
			begin
				instr_index = test_buf.addr + test_buf.op_1;
			end
		end
		else
		if(test_buf.cmd == "ADD")
		begin
			mock_reg[test_buf.op_1] = mock_reg[test_buf.op_1] + mock_reg[test_buf.op_2];
		end
		else
		if(test_buf.cmd == "SUB")
		begin
			mock_reg[test_buf.op_1] = mock_reg[test_buf.op_1] - mock_reg[test_buf.op_2];
		end
		else
		if(test_buf.cmd == "MUL")
		begin
			mock_reg[test_buf.op_1] = mock_reg[test_buf.op_1] * mock_reg[test_buf.op_2];
		end
		else
		if(test_buf.cmd == "AND")
		begin
			mock_reg[test_buf.op_1] = mock_reg[test_buf.op_1] & mock_reg[test_buf.op_2];
		end
		else
		if(test_buf.cmd == "OR")
		begin
			mock_reg[test_buf.op_1] = mock_reg[test_buf.op_1] | mock_reg[test_buf.op_2];
		end
		else
		if(test_buf.cmd == "XOR")
		begin
			mock_reg[test_buf.op_1] = mock_reg[test_buf.op_1] ^ mock_reg[test_buf.op_2];
		end
		else
		if(test_buf.cmd == "CMP1")
		begin
			mock_reg[test_buf.op_1] = ~mock_reg[test_buf.op_1];
		end
		else
		if(test_buf.cmd == "CMP2")
		begin
			mock_reg[test_buf.op_1] = (~mock_reg[test_buf.op_1]) + 1;
		end
		else
		if(test_buf.cmd == "CPP")
		begin
			if(mock_reg[test_buf.op_1] == mock_reg[test_buf.op_2])
			begin
				compare_flags[0] = 1;
				compare_flags[1] = 0;
				compare_flags[2] = 0;
			end
			else
			if(mock_reg[test_buf.op_1] < mock_reg[test_buf.op_2])
			begin
				compare_flags[0] = 0;
				compare_flags[1] = 1;
				compare_flags[2] = 0;
			end
			else
			if(mock_reg[test_buf.op_1] > mock_reg[test_buf.op_2])
			begin
				compare_flags[0] = 0;
				compare_flags[1] = 0;
				compare_flags[2] = 1;
			end
		end
		else
		if(test_buf.cmd == "MOV")
		begin
			mock_reg[test_buf.op_1] = mock_reg[test_buf.op_2];
		end
		else
		if(test_buf.cmd == "ADDI")
		begin
			mock_reg[test_buf.op_1] = mock_reg[test_buf.op_1] + {7'b0, 9'(test_buf.op_2)};
		end
		else
		if(test_buf.cmd == "SUBI")
		begin
			mock_reg[test_buf.op_1] = mock_reg[test_buf.op_1] - {7'b0, 9'(test_buf.op_2)};
		end
		else
		begin
			$display("Unknown instruction in test");
			$stop;
		end

		if(mem_compare() == 0)
		begin
			$display("Runtime error @instruction %d: %s %d, %d", pending_index-1, test_buf.cmd, test_buf.op_1, test_buf.op_2);
			$stop;
		end
	end

	if(TOP.CPU.CORE.load_2 == 1'b1)
	begin
		if(pending == 1)
		begin
			next_check = 1;
			test_buf = pipe_buf[2];
		end
		else
		begin
			next_check = 0;
		end
		pipe_buf[2] = pipe_buf[1];
		pending = 1;
		pending_index ++;
	end
	else 
	if(TOP.CPU.CORE.stage_2_buf[TOP.CPU.CORE.s_2_valid] == 1'b0)
	begin
		pending = 0;
	end

	if(TOP.CPU.CORE.load_1 == 1'b1)
	begin
		pipe_buf[1] = pipe_buf[0];
	end
	
	if(TOP.CPU.CORE.load_0 == 1'b1)
	begin
		pipe_buf[0] = instr_list[instr_index];
		instr_index ++;
	end

end


assign cpu_enable = 1'b1;

/* In case we want to enable the CPU at a later time
always_ff @(posedge clk or posedge rst)
begin

	if(rst == 1'b1)
	begin
		cpu_enable <= 1'b0;
	end
	else
	begin
		if(TOP.mem_rdy == 1'b1)
		begin
			cpu_enable <= 1'b1;
		end
	end
end
*/

always @(posedge clk)
begin

	if(TOP.MEM_CTRL.MEM_DRV.state == TOP.MEM_CTRL.MEM_DRV.MEM_WRITE)
	begin
		sym_mem[TOP.MEM_CTRL.MEM_DRV.mem_addr_buf] = TOP.MEM_CTRL.MEM_DRV.mem_data_in_buf;
	end

end

assign sdram_dq = 	TOP.MEM_CTRL.MEM_DRV.state == TOP.MEM_CTRL.MEM_DRV.MEM_READ &&
					TOP.MEM_CTRL.MEM_DRV.timer == 16'd4
					? sym_mem[TOP.MEM_CTRL.MEM_DRV.mem_addr_buf] : ($bits(sdram_dq))'('bz);

endmodule