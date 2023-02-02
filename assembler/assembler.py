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

def parse(file_name):
    instr_list = []
    line_count = 0

    with open(file_name, mode='r') as read_file:
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
    
    print(instr_list)
    return instr_list
    
def assemble(instr_list):
    with open('out', mode='wb') as write_file:
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
                    
                    instr_arg = int(instr_arg)
                    if instr_arg < 0:
                        if isa_arg['TYPE'] == 'REG':
                            throw_syntax_error(instr, instr_num, 'Register index must be positive')
                        # take the compliment
                        instr_arg = -instr_arg
                        if instr_arg > 2**(isa_arg['WIDTH'] - 1):
                            throw_syntax_error(instr, instr_num, 'Negative value out of bounds')
                        instr_arg = 2**isa_arg['WIDTH'] - instr_arg

                    # write instr_arg as binary format with minimum isa_arg['WIDTH'] digits
                    instr_arg = '{:0={}b}'.format(instr_arg, isa_arg['WIDTH'])
                    if len(instr_arg) > isa_arg['WIDTH']:
                        throw_syntax_error(instr, instr_num, 'Positive value out of bounds')
                    
                    write_str += instr_arg

                print(write_str)
                write_file.write(int(write_str, 2).to_bytes(2, byteorder='big'))

            except KeyError:
                throw_syntax_error(instr, instr_num, 'Unknown instruction')
            
            except ValueError:
                throw_syntax_error(instr, instr_num, 'Expecting number')


if __name__ == "__main__":
    #print('Arguments count: ', len(sys.argv))
    for i, arg in enumerate(sys.argv):
        #print(f'Argument {i}: {arg}')
        if i != 0:
            assemble(parse(arg))
            #parse(arg)
            #assemble(5)
