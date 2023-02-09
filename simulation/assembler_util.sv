function string get_next_arg(string line, output string remainder);

	if(line.len() == 0 || line.getc(0) == ",")
	begin
		remainder = "";
		return "";
	end

	for(int i = 0;i < line.len();i ++)
	begin
		if(line.getc(i) == ",")
		begin
			remainder = line.substr(i+1, line.len()-1);
			if(line.getc(0) == "$")
			begin
				// Strip the dollar sign. This will break legacy simulation.
				return line.substr(1, i-1);
			end
			else
			begin
				return line.substr(0, i-1);
			end
		end
		else
		if(i == line.len() - 1)
		begin
			remainder = "";
			if(line.getc(0) == "$")
			begin
				// Strip the dollar sign. This will break legacy simulation.
				return line.substr(1, i);
			end
			else
			begin
				return line.substr(0, i);
			end
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


function void throw_fatal_error(string hint, int optional_line_num);

	$display("!!! FATAL SIMULATION ERROR !!!");
	if(optional_line_num >= 0)
	begin
		$display("@ line %d", optional_line_num);
	end
	$display(hint);
	$stop;

endfunction