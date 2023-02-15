import sys
from isa_lib import *

def throw_syntax_error(line, line_num, hint):
    print('Syntax error at line ', line_num, ' : ', line, '\n', hint)
    exit(1)

def is_comment(line):
    if len(line) >= 2 and line[0] == '/' and line[1] == '/':
        return True
    else:
        return False

def parse(read_file_name):
    instr_list = []
    line_count = 0

    with open(read_file_name, mode='r') as read_file:
        for line in read_file:
            line_count += 1

            line = line.strip()
            if len(line) == 0:
                continue
            if is_comment(line):
                continue

            line_list = line.replace(',','').split()
            if len(line_list) < 2:
                # should be okay indexing 0 since it should not be 0 length
                throw_syntax_error(line_list[0], line_count, 'Expecting more words')

            instr_list.append(line_list)
    
    return instr_list
    

def assemble(write_file_name, instr_list):
    with open(write_file_name, mode='wb') as write_file:
        instr_num = 0
        for instr in instr_list:
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


if __name__ == "__main__":
    if len(sys.argv) == 3:
        assemble(sys.argv[2], parse(sys.argv[1]))
    elif len(sys.argv) == 2 and sys.argv[1] == 'help':
        print('--HELP--\n', sys.argv[0], ' input_file output_file')
    else:
        print('Expecting 2 arguments for ', sys.argv[0])
