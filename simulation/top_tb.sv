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

logic [15:0] mem_map_init_addresses;
logic [15:0] mem_map_init_values;

top TOP
	(
	.clk(clk),
	.rst_n(~rst),

	.led(led),
	.sdram_clk(sdram_clk),     //sdram clock
	.sdram_cke(sdram_cke),    //sdram clock enable
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

	.cpu_enable(cpu_enable),

	.mem_map_init_addresses(mem_map_init_addresses),
	.mem_map_init_values(mem_map_init_values)
	);

assign uart_rx = 1'b1;

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

function void init_program();

	automatic int binary_file;
	automatic int symbol_file;
	automatic string line;
	automatic string arg;
	automatic int op;
	automatic int status;
	automatic logic [7:0] file_byte;
	automatic int is_high_byte = 1;
	automatic int mem_addr = 0;
	automatic int i;

	mem_map_init_addresses = 16'd30;

	$display("SIMULATION SETUP STARTING\n");
	$display("Running toolchain...\n");

	$system("python ../assembler/generator.py random ../assembler/programs/gen.jasm");
	$system("python ../assembler/assembler.py ../assembler/programs/gen.jasm ../assembler/programs/out");
	$system("python ../assembler/disassembler.py ../assembler/programs/out ../assembler/programs/dis.jasm");

	$display("Toolchain complete. Processing binary file...\n");

	binary_file = $fopen("../assembler/programs/out", "rb");
	if(binary_file == 0)
	begin
		throw_fatal_error("Error opening binary file", -1);
	end

	while(1)
	begin
		/*
		 Read binary file byte by byte and alternate between 
		 writing to high and low field of memory
		*/
		$fread(file_byte, binary_file);
		if($feof(binary_file))
		begin
			break;
		end

		if(is_high_byte == 1)
		begin
			is_high_byte = 0;
			mock_mem[mem_addr][15:8] = file_byte;
		end
		else
		begin
			is_high_byte = 1;
			mock_mem[mem_addr][7:0] = file_byte;
			mem_addr += 1;
		end
	end

	$fclose(binary_file);

	if(mem_addr == 0)
	begin
		throw_fatal_error("Binary file has less than 2 bytes", -1);
	end
	else
	if(is_high_byte != 1)
	begin
		throw_fatal_error("Binary file has an odd number of bytes", -1);
	end

	// Fill the rest of memory with 0
	for( ;mem_addr < MEM_SIZE;mem_addr ++)
	begin
		mock_mem[mem_addr] = 16'b0;
	end

	$display("Processing binary file complete. Processing symbol file...\n");

	mem_addr = 0;
	symbol_file = $fopen("../assembler/programs/dis.jasm", "r");
	if(symbol_file == 0)
	begin
		throw_fatal_error("Error opening symbol file", -1);
	end

	while(1)
	begin
		/*
		 Read the disassembly so we can use that for checking instruction
		 behavior instead of having to write a new disassembler here
		*/
		void'($fgets(line, symbol_file));
		if($feof(symbol_file))
		begin
			break;
		end

		if(line.len() == 0)
		begin
			continue;
		end

		arg = get_cmd(line, line);
		if(arg != "")
		begin
			instr_list[mem_addr].cmd = arg;
		end
		else
		begin
			throw_fatal_error("Missing command", mem_addr);
		end

		line = strip_all_whitespace(line);

		arg = get_next_arg(line, line);
		if(arg != "")
		begin
			op = const_decode(arg, status);
			instr_list[mem_addr].op_1 = op;
			arg = get_next_arg(line, line);
			if(arg != "")
			begin
				op = const_decode(arg, status);
				instr_list[mem_addr].op_2 = op;
			end
		end
		else
		begin
			throw_fatal_error("No arguments provided", mem_addr);
		end

		instr_list[mem_addr].addr = mem_addr;

		$display("%x: %s %d %d", 	instr_list[mem_addr].addr, 
									instr_list[mem_addr].cmd, 
									instr_list[mem_addr].op_1, 
									instr_list[mem_addr].op_2);

		mem_addr += 1;
	end

	$fclose(symbol_file);

	if(mem_addr == 0)
	begin
		throw_fatal_error("Symbol file has no data", -1);
	end

	for(i = 0;i < MEM_SIZE;i ++)
	begin
		if(i == mem_map_init_addresses)
		begin
			mem_map_init_values = mock_mem[i];
			$display("Init mem_map: %x", mem_map_init_values);
		end
		else
		begin
			sym_mem[i] = mock_mem[i];
		end
	end

	for(i = 0;i < REG_FILE_SIZE;i ++)
	begin
		mock_reg[i] = 0;
	end

	$display("Simulation setup complete.\n");
	$display("STARTING SIMULATION\n");

endfunction

int sim_pc;
instr_list_t test_buf;
int compare_flags[8];
int check_valid_plus_load_next;
int check_valid_plus_invalid_next;
instr_list_t instr_queue[$];

function void init_tb();

	sim_pc = 0;
	check_valid_plus_load_next = 0;
	check_valid_plus_invalid_next = 0;

	for(int i = 0;i < 7; i ++)
	begin
		compare_flags[i] = 0;
	end

	test_buf.cmd = "";
	test_buf.op_1 = 0;
	test_buf.op_2 = 0;
	test_buf.addr = 0;

endfunction


function int mem_compare();

	automatic int ret = 1;

	for(int i = 0;i < MEM_SIZE;i ++)
	begin
		if(i == mem_map_init_addresses)
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
	if(sim_pc != PROC.pc)
	begin
		$display("mock != PC: %x != %x", sim_pc, PROC.pc);
		ret = 0;
	end
	*/

	return ret;

endfunction

function void empty_queue(instr_list_t input_queue[$]);

	while(input_queue.size() > 0)
	begin
		input_queue.pop_front();
	end

endfunction


always @(posedge clk)
begin

	if(check_valid_plus_load_next == 1'b1 || (check_valid_plus_invalid_next == 1'b1 && TOP.CPU.CORE.stage_2_buf[TOP.CPU.CORE.s_2_valid] == 1'b0))
	begin
		// sanity check the queue size
		if(instr_queue.size() < 1)
		begin
			throw_fatal_error("Empty queue with instruction complete signal", -1);
		end

		check_valid_plus_load_next = 0;
		check_valid_plus_invalid_next = 0;

		
		test_buf = instr_queue.pop_front();
		$display("%x: %s %d, %d          | %x", test_buf.addr, test_buf.cmd, test_buf.op_1, test_buf.op_2, test_buf.addr == mem_map_init_addresses ? TOP.MEM_CTRL.seg_val[15:0] : mock_mem[test_buf.addr]);

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
			sim_pc = test_buf.addr + test_buf.op_1;
			// Clear queue
			while(instr_queue.size() > 0) instr_queue.pop_front(); // TODO: Make a function for this
		end
		else
		if(test_buf.cmd == "BEQ")
		begin
			if(compare_flags[0] == 1)
			begin
				sim_pc = test_buf.addr + test_buf.op_1;
				// Clear queue
				while(instr_queue.size() > 0) instr_queue.pop_front(); // TODO: Make a function for this
			end
		end
		else
		if(test_buf.cmd == "BNE")
		begin
			if(compare_flags[0] == 0)
			begin
				sim_pc = test_buf.addr + test_buf.op_1;
				// Clear queue
				while(instr_queue.size() > 0) instr_queue.pop_front(); // TODO: Make a function for this
			end
		end
		else
		if(test_buf.cmd == "BLT")
		begin
			if(compare_flags[1] == 1)
			begin
				sim_pc = test_buf.addr + test_buf.op_1;
				// Clear queue
				while(instr_queue.size() > 0) instr_queue.pop_front(); // TODO: Make a function for this
			end
		end
		else
		if(test_buf.cmd == "BGT")
		begin
			if(compare_flags[2] == 1)
			begin
				sim_pc = test_buf.addr + test_buf.op_1;
				// Clear queue
				while(instr_queue.size() > 0) instr_queue.pop_front(); // TODO: Make a function for this
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
			$display("Runtime error @ %d: %s %d, %d", test_buf.addr, test_buf.cmd, test_buf.op_1, test_buf.op_2);
			$stop;
		end
	end

	if(TOP.CPU.CORE.stage_2_buf[TOP.CPU.CORE.s_2_valid] == 1'b1 && TOP.CPU.CORE.load_2 == 1'b1)
	begin
		check_valid_plus_load_next = 1;
	end
	else
	if(TOP.CPU.CORE.stage_2_buf[TOP.CPU.CORE.s_2_valid] == 1'b1)
	begin
		check_valid_plus_invalid_next = 1;
	end

	if(TOP.CPU.CORE.load_0 == 1'b1)
	begin
		instr_queue.push_back(instr_list[sim_pc]);
		sim_pc ++;
	end

end


// Bypass system init module
assign cpu_enable = 1'b1;

// Simulate DRAM
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



int clk_count;
int iter_count;

initial
begin
	init_program();
	init_tb();
	clk_count = 0;
	iter_count = 1;

	clk <= 1'b0;
    rst <= 1'b1;
    #2;
    rst <= 1'b0;
end

always 
begin
    clk = ~clk; 
    #1;
end

always @(posedge clk)
begin

	clk_count ++;
	if(clk_count == 20000)
	begin
		rst <= 1'b1;

		iter_count ++;

		$display("\n\n
=======================================================================================================
                                        STARTING RUN #%d
=======================================================================================================
\n\n", iter_count);

		init_program();
		init_tb();
		clk_count = 0;
		while(instr_queue.size() > 0) instr_queue.pop_front(); // TODO: Make a function for this

		#1;
		rst <= 1'b0;
	end
	
end

endmodule
