module assembler;

parameter MEM_ADDR_WIDTH = 16;
parameter REG_ADDR_WIDTH = 4;
parameter DATA_WIDTH = 16;
parameter MEM_SIZE = 65536;
parameter REG_FILE_SIZE = 16;

function string get_next_arg(string line, output string remainder);

	for(int i = 0;i < line.len();i ++)
	begin
		if(line.getc(i) == ",")
		begin
			if(i == 0 || i == line.len()-1)
			begin
				remainder = "";
				return "";
			end
			remainder = line.substr(i+1, line.len()-1);
			return line.substr(0, i-1);
		end
	end
	remainder = "";
	return line.substr(0, line.len()-1);

endfunction

function string strip_all_whitespace(string line);

	automatic string out = "";
	
	for(int i = 0;i < line.len();i ++)
	begin
		if(line.getc(i) != " " && line.getc(i) != "\n")
		begin
			out = {out, line.getc(i)};
		end
	end

	return out;

endfunction

function string strip_leading_whitespace(string line);
	
	for(int i = 0;i < line.len();i ++)
	begin
		if(line.getc(i) != " ")
		begin
			if(i == line.len()-1)
			begin
				return string'(line.getc(i));
			end
			return line.substr(i, line.len()-1);
		end
	end

	return "";

endfunction


function string get_cmd(string line, output string remainder);

	for(int i = 0;i < line.len();i ++)
	begin
		if(line.getc(i) == " ")
		begin
			if(i == 0 || i == line.len()-1)
			begin
				break;
			end
			remainder = line.substr(i+1, line.len()-1);
			return line.substr(0, i-1);
		end
	end
	
	return "";

endfunction


function int reg_decode(string reg_str, output int status);

	automatic int result = 0;
	automatic int mul = 1;

	if(reg_str.len() < 2 || reg_str.getc(0) != "$")
	begin
		status = 0;
		return 0;
	end

	for(int i = reg_str.len()-1;i > 0;i --)
	begin
		if(!(reg_str.getc(i) >= "0" && reg_str.getc(i) <= "9"))
		begin
			status = 0;
			return 0;
		end

		result += (reg_str.getc(i) - "0") * mul;
		mul *= 10;
	end

	status = 1;
	return result;

endfunction

function int const_decode(string const_str, output int status);

	automatic int result = 0;
	automatic int mul = 1;

	if(const_str.len() == 0)
	begin
		status = 0;
		return 0;
	end
	
	if(const_str.len() > 2 && const_str.getc(0) == "0" && const_str.getc(1) == "x")
	begin
		for(int i = const_str.len()-1;i >= 2;i --)
		begin
			if(i == 2 && const_str.getc(i) == "-")
			begin
				result = -result;
			end
			else
			begin
				if(const_str.getc(i) == "a" || const_str.getc(i) == "A")
				begin
					result += 10 * mul;
				end
				else
				if(const_str.getc(i) == "b" || const_str.getc(i) == "B")
				begin
					result += 11 * mul;
				end
				else
				if(const_str.getc(i) == "c" || const_str.getc(i) == "C")
				begin
					result += 12 * mul;
				end
				else
				if(const_str.getc(i) == "d" || const_str.getc(i) == "D")
				begin
					result += 13 * mul;
				end
				else
				if(const_str.getc(i) == "e" || const_str.getc(i) == "E")
				begin
					result += 14 * mul;
				end
				else
				if(const_str.getc(i) == "f" || const_str.getc(i) == "F")
				begin
					result += 15 * mul;
				end
				else
				begin
					if(!(const_str.getc(i) >= "0" && const_str.getc(i) <= "9"))
					begin
						status = 0;
						return 0;
					end

					result += (const_str.getc(i) - "0") * mul;
				end

				mul *= 16;
			end
		end
	end
	else
	begin
		for(int i = const_str.len()-1;i >= 0;i --)
		begin
			if(i == 0 && const_str.getc(i) == "-")
			begin
				result = -result;
			end
			else
			begin
				if(!(const_str.getc(i) >= "0" && const_str.getc(i) <= "9"))
				begin
					status = 0;
					return 0;
				end

				result += (const_str.getc(i) - "0") * mul;
				mul *= 10;
			end
		end
	end

	status = 1;
	return result;

endfunction

function int is_comment(string line);

	if(line.len() >= 2)
	begin
		if(line.getc(0) == "/" && line.getc(1) == "/")
		begin
			return 1;
		end
	end

	return 0;

endfunction

logic[MEM_SIZE-1:0][DATA_WIDTH-1:0] mem;

initial
begin

	int read_file;
	int write_file;
	string line;
	string cmd;
	string arg_1;
	string arg_2;
	string arg_3;
	int op_1;
	int op_2;
	int status;
	int i = 0;
	int out, in;

	$display("==========\nStart of file read and mem init\n==========\n");

	$system("python generator.py random");


	$fclose(out);
	$fclose(in);

	$stop;

	read_file = $fopen("tester.jasm", "r");
	write_file = $fopen("out", "wb");

	if(read_file == 0)
	begin
		$display("Error opening file");
	end

	while(!$feof(read_file))
	begin
		void'($fgets(line, read_file));
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

			mem[i][DATA_WIDTH-1:0] = {4'b0110, 8'(op_2), 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {4'b0111, 8'(op_2), 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b000, 9'(op_2), 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b10000, 4'(op_2), 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b010, 9'(op_1), 4'(op_2)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b10001, 4'(op_1), 4'(op_2)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b001, 13'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {5'b10000, 11'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {5'b10001, 11'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {5'b10010, 11'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {5'b10011, 11'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00000, 4'(op_2), 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00001, 4'(op_2), 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00010, 4'(op_2), 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00011, 4'(op_2), 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00100, 4'(op_2), 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00101, 4'(op_2), 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00110, 4'b0, 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b00111, 4'b0, 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b01000, 4'(op_2), 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b111, 5'b10010, 4'(op_2), 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b101, 9'(op_2), 4'(op_1)};
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

			mem[i][DATA_WIDTH-1:0] = {3'b110, 9'(op_2), 4'(op_1)};
		end
		else
		begin
			$display("Unknown instruction @line %d", i);
			$stop;
		end
			
		$display("%x", mem[i]);
		// write in little endian
		$fdisplay(write_file, "%u", mem[i][DATA_WIDTH/2 - 1:0]);
		$fdisplay(write_file, "%u", mem[i][DATA_WIDTH-1:DATA_WIDTH/2]);
		$display("%u", mem[i][DATA_WIDTH/2 - 1:0]);
		$display("%u", mem[i][DATA_WIDTH-1:DATA_WIDTH/2]);
		i += 1;

	end

	$fclose(read_file);
	$fclose(write_file);

	$stop;
end

endmodule