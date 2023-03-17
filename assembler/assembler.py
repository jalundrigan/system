import sys
from isa_lib import *

def throw_syntax_error(line, line_num, hint):
    print('Fatal syntax error at line ', line_num, ' : ', line, '\n', hint)
    exit(1)

def throw_generic_error(hint):
    print('Fatal error: ', hint)
    exit(1)

def is_comment(line):
    if len(line) >= 2 and line[0] == '/' and line[1] == '/':
        return True
    else:
        return False
    
def is_data_section_directive(line):
    if line == '.data':
        return True
    else:
        return False

def is_text_section_directive(line):
    if line == '.text':
        return True
    else:
        return False


# .data section formats
#   1)      tag: 
#               1234
#   2)      9876:
#               1234
#   3)      tag(9876):
#               1234
#   4)      tag: 1234
#   5)      9876: 1234
#   6)      tag(9876): 1234

# .text section formats
#   1)      tag: ADDI $0, $1
#   2)      tag: 
#               ADDI $0, $1

def get_tag(cmd):
    cmd_len = len(cmd)
    colon_index = cmd.find(':')
    is_only_tag = False

    if colon_index == -1:
        # no tag
        return None, False, False, False
    elif colon_index == cmd_len - 1:
        is_only_tag = True
    
    tag = cmd[0:colon_index].strip()

    open_brk_index = tag.find('(')
    close_brk_index = tag.find(')')

    if open_brk_index != -1 and close_brk_index != -1:
        # the tag has both a symbolic and literal
        return tag, True, True, is_only_tag

    try:
        int(tag)
        # tag is literal
        return tag, True, False, is_only_tag
    except ValueError:
        # tag is symbolic
        return tag, False, True, is_only_tag

def get_value(cmd):
    colon_index = cmd.find(':')
    val_str = ''
    if colon_index == -1:
        val_str = cmd
    else:
        val_str = cmd[colon_index + 1:]
    
    val_str = val_str.strip()
    try:
        ret = int(val_str)
        return ret
    except ValueError:
        return None

def get_symbol(tag):
    open_brk_index = tag.find('(')
    close_brk_index = tag.find(')')

    if open_brk_index != -1 and close_brk_index != -1:
        return tag[0:open_brk_index]
    else:
        return tag

def get_literal(tag):
    open_brk_index = tag.find('(')
    close_brk_index = tag.find(')')
    val_str = ''

    if open_brk_index != -1 and close_brk_index != -1:
        val_str = tag[open_brk_index+1:close_brk_index]
    else:
        val_str = tag

    try:
        ret = int(val_str)
        return ret
    except ValueError:
        return None

def strip_tag_from_line(line):
    colon_index = line.find(':')
    return line[colon_index + 1:].strip()

def generate_from_literal(address_lit, value):
    gen = []
    gen.append('LLI $0, ' + str(address_lit & 0xff))
    gen.append('LUI $0, ' + str(address_lit >> 8))
    gen.append('LLI $1, ' + str(value & 0xff))
    gen.append('LUI $1, ' + str(value >> 8))
    gen.append('STI $0, $1')
    return gen

def generate_from_symbol(address_symb, value):
    gen = []
    gen.append('LLI $0, ' + address_symb + ' & 0xff')
    gen.append('LUI $0, ' + address_symb + ' >> 8')
    gen.append('LLI $1, ' + str(value & 0xff))
    gen.append('LUI $1, ' + str(value >> 8))
    gen.append('STI $0, $1')
    return gen


def generate_data_section_code(data_section_list):
    new_text_section_list = []
    tag_list = []
    auto_tag_list = []

    pending_tag = None
    index = 0
    for line in data_section_list:
        tag, is_literal, is_symbolic, is_only_tag = get_tag(line)
        if pending_tag != None:
            if tag != None:
                throw_syntax_error(line, index, 'Unexpected tag in .data section')
            else:
                tag, is_literal, is_symbolic = pending_tag
                is_only_tag = False
                pending_tag = None

        if tag != None:
            if is_only_tag == True:
                pending_tag = tag, is_literal, is_symbolic
            else:
                value = get_value(line)
                if value == None:
                    throw_syntax_error(line, index, 'Bad value field in .data section')

                if is_literal == True and is_symbolic == True:
                    literal = get_literal(tag)
                    symbol = get_symbol(tag)
                    tag_list.append([symbol, literal])
                    gen = generate_from_literal(literal, value)
                    new_text_section_list += gen
                elif is_literal == True:
                    literal = get_literal(tag)
                    gen = generate_from_literal(literal, value)
                    new_text_section_list += gen
                elif is_symbolic == True:
                    symbol = get_symbol(tag)
                    auto_tag_list.append(symbol)
                    gen = generate_from_symbol(symbol, value)
                    new_text_section_list += gen
                    
            index += 1

        else:
            throw_syntax_error(line, index, 'Missing tag in .data section')

    return new_text_section_list, tag_list, auto_tag_list

def get_sections(prog_list):
    data_section_index = -1
    text_section_index = -1
    data_section_list = []
    text_section_list = []

    index = 0
    for line in prog_list:
        if is_data_section_directive(line):
            if data_section_index >= 0:
                throw_generic_error('More than one .data section specified')
            else:
                data_section_index = index
        elif is_text_section_directive(line):
            if text_section_index >= 0:
                throw_generic_error('More than one .text section specified')
            else:
                text_section_index = index

        index += 1

    if data_section_index < 0:
        throw_generic_error('No .data section specified')
    
    if text_section_index < 0:
        throw_generic_error('No .text section specified')


    if data_section_index < text_section_index:
        data_section_list = prog_list[data_section_index+1:text_section_index]
        text_section_list = prog_list[text_section_index+1:]
    elif data_section_index > text_section_index:
        data_section_list = prog_list[data_section_index+1:]
        text_section_list = prog_list[text_section_index+1:data_section_index]

    return data_section_list, text_section_list


def get_text_section_tags(text_section_list, text_section_offset):
    tag_list = []
    index = 0
    for line in text_section_list:
        tag, is_literal, is_symbolic, is_only_tag = get_tag(line)
        if tag != None:
            tag_list.append([tag, index + text_section_offset])
            if is_only_tag == True:
                del text_section_list[index]
                continue
            else:
                text_section_list[index] = strip_tag_from_line(line)

        index += 1

    return tag_list, text_section_list

def resolve_auto_tags(auto_tag_list, offset):
    ret_list = []
    for tag in auto_tag_list:
        ret_list.append([tag, offset])
        offset += 1

    return ret_list

def resolve_tags(program_list, tag_list):
    new_program_list = []
    for line in program_list:
        for tag in tag_list:
            if line.find(tag[0]) != -1:
                line = line.replace(tag[0], str(tag[1]))

        new_program_list.append(line)
    
    return new_program_list


def resolve_operations(split_program_list):
    resolved_list = []
    index = 0
    for line_list in split_program_list:
        resolved_line = []
        for item in line_list:
            if  item.find('+') != -1 or \
                item.find('-') != -1 or \
                item.find('*') != -1 or \
                item.find('/') != -1 or \
                item.find('>>') != -1 or \
                item.find('<<') != -1 or \
                item.find('&') != -1 or \
                item.find('|') != -1:
                try:
                    resolved_line.append(str(eval(item)))
                except SyntaxError:
                    throw_syntax_error(line_list, index, '')

            else:
                resolved_line.append(item)
        
        resolved_list.append(resolved_line)
        index += 1
    
    return resolved_list

def pre_parse(prog_list):
    data_section_list, text_section_list = get_sections(prog_list)

    program_list, tag_list, auto_tag_list = generate_data_section_code(data_section_list)

    text_section_offset = len(program_list)
    text_section_tag_list, text_section_list = get_text_section_tags(text_section_list, text_section_offset)
   
    tag_list += text_section_tag_list
    program_list += text_section_list

    auto_tag_list = resolve_auto_tags(auto_tag_list, text_section_offset + len(text_section_list))
    print(auto_tag_list)
    if auto_tag_list != None:
        tag_list += auto_tag_list

    print('Before tag resolution==========')
    for line in program_list:
        print(line)
    
    program_list = resolve_tags(program_list, tag_list)

    print('After tag resolution==========')
    for line in program_list:
        print(line)

    split_program_list = []
    for line in program_list:
        # split command from first operand
        line = line.split(' ', 1)
        remainder = line[1]
        del line[1]
        # break rest of line up by comma
        line += remainder.split(',')
        for i in range(len(line)):
            line[i] = line[i].strip()

        split_program_list.append(line)

    print('After split==========')
    for line in split_program_list:
        print(line)

    split_program_list = resolve_operations(split_program_list)

    print('After resolving==========')
    for line in split_program_list:
        print(line)

    return split_program_list

def assemble(write_file_name, prog_list):

    with open(write_file_name, mode='wb') as write_file:
        instr_num = 0
        for instr in prog_list:
            try:
                isa_entry = isa[instr[0]]
                if  len(instr) - 1 != len(isa_entry['ARGS']):
                    # check length again in case there are don't cares
                    asm_arg_count = 0
                    for i in isa_entry['ARGS']:
                        if i['TYPE'] != None:
                            asm_arg_count += 1
                    if len(instr) - 1 != asm_arg_count:                        
                        throw_syntax_error(instr, instr_num, 'Incorrect number of arguments')
                
                write_str = isa_entry['OPCODE']
                for isa_arg in isa_entry['ARGS']:
                    if isa_arg['TYPE'] == None:
                        write_str += '0' * isa_arg['WIDTH']
                        continue

                    instr_arg = instr[isa_arg['ASM_INDEX'] + 1]
                    if isa_arg['TYPE'] == 'REG':
                        if instr_arg[0] != '$':
                            throw_syntax_error(instr, instr_num, 'Expecting register')
                        instr_arg = instr_arg[1:]
                    
                    # try to convert the argument to an int with a few different bases
                    try:
                        instr_arg = int(instr_arg)
                    except ValueError:
                        try:
                            instr_arg = int(instr_arg, 2)
                        except ValueError:
                            try:
                                instr_arg = int(instr_arg, 16)
                            except ValueError:
                                throw_syntax_error(instr, instr_num, 'Expected a number in base 2, 10, or 16')

                    if (isa_arg['SIGNED'] == False) and (instr_arg > 2**(isa_arg['WIDTH']) - 1):
                        throw_syntax_error(instr, instr_num, 'Unsigned argument out of bounds (too large)')
                    elif (isa_arg['SIGNED'] == False) and (instr_arg < 0):
                        throw_syntax_error(instr, instr_num, 'Expecting unsigned argument')
                    elif (isa_arg['SIGNED'] == True) and (instr_arg > 2**(isa_arg['WIDTH'] - 1) - 1):
                        throw_syntax_error(instr, instr_num, 'Signed argument out of bounds (too large)')
                    elif (isa_arg['SIGNED'] == True) and (instr_arg < -2**(isa_arg['WIDTH'] - 1)):
                        throw_syntax_error(instr, instr_num, 'Signed argument out of bounds (too small)')
                    elif (isa_arg['SIGNED'] == True) and (instr_arg < 0):
                        # take the compliment
                        instr_arg = 2**isa_arg['WIDTH'] + instr_arg

                    # write instr_arg as binary format with minimum isa_arg['WIDTH'] digits
                    instr_arg = '{:0={}b}'.format(instr_arg, isa_arg['WIDTH'])
                    if len(instr_arg) > isa_arg['WIDTH']:
                        throw_syntax_error(instr, instr_num, '!!! FATAL ASSEMBLER ERROR !!!')
                    
                    write_str += instr_arg

                write_file.write(int(write_str, 2).to_bytes(2, byteorder='big'))

            except KeyError:
                throw_syntax_error(instr, instr_num, 'Unknown instruction')
            
            except ValueError:
                throw_syntax_error(instr, instr_num, 'Fatal write arg')


def get_prog_list(read_file_name):
    prog_list = []
    line_count = 0

    with open(read_file_name, mode='r') as read_file:
        for line in read_file:
            line_count += 1

            line = line.strip()
            if len(line) == 0:
                continue
            elif is_comment(line):
                continue

            prog_list.append(line)
    
    return prog_list

if __name__ == "__main__":
    if len(sys.argv) == 3:
        assemble(sys.argv[2], pre_parse(get_prog_list(sys.argv[1])))
    elif len(sys.argv) == 2 and sys.argv[1] == 'help':
        print('--HELP--\n', sys.argv[0], ' input_file output_file')
    else:
        print('Expecting 2 arguments for ', sys.argv[0])
