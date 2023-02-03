import sys
from isa_lib import *

def throw_syntax_error(line, line_num, hint):
    print('Syntax error at line ', line_num, ' : ', line, '\n', hint)
    exit(1)

def parse(read_file_name):
    instr_list = []
    line_count = 0

    with open(read_file_name, mode='rb') as read_file:

        while True:
            high = read_file.read(1)
            if not high:
                break
            low = read_file.read(1)
            if not low:
                throw_syntax_error(line_count, str(low), 'Missing second byte')
            
            instr_list.append( (int.from_bytes(high, 'big') << 8) | int.from_bytes(low, 'big') )
            line_count += 1
        
        if line_count == 0:
            throw_syntax_error(line_count, '', 'No data')
    
    return instr_list


def disassemble(write_file_name, instr_list):
    with open(write_file_name, mode='w') as write_file:
        isa_list = list(isa)
        instr_num = 0
        for instr in instr_list:
            write_instr = ''
            for instr_name in isa_list:
                isa_entry = isa[instr_name]
                isa_opcode_str = isa_entry['OPCODE']
                isa_opcode = int(isa_opcode_str, 2)
                isa_opcode_len = len(isa_opcode_str)

                instr_opcode = instr >> (16 - isa_opcode_len)
                if instr_opcode == isa_opcode:
                    shift_point = 16 - isa_opcode_len
                    write_instr += instr_name + ' '
                    num_args = len(isa_entry['ARGS'])
                    write_arg_list = num_args*['']
                    
                    for isa_arg in isa_entry['ARGS']:
                        instr_mask = 2**isa_arg['WIDTH'] - 1
                        instr_arg = instr >> (shift_point - isa_arg['WIDTH'])
                        instr_arg = instr_arg & instr_mask
                        shift_point = shift_point - isa_arg['WIDTH']

                        if isa_arg['TYPE'] == None:
                            continue
                        elif isa_arg['TYPE'] == 'REG':
                            write_arg_list[isa_arg['ASM_INDEX']] += '$'
                        
                        if isa_arg['SIGNED'] == True:
                            if instr_arg >= 2**(isa_arg['WIDTH'] - 1):
                                # take the compliment
                                instr_arg = -(2**(isa_arg['WIDTH']) - instr_arg)

                        write_arg_list[isa_arg['ASM_INDEX']] += str(instr_arg)

                    for arg in write_arg_list:
                        if len(arg) != 0:
                            write_instr += arg + ', '   
                    
                    # Found the opcode and disassembled the instruction. Move to next instruction.
                    break             

            if len(write_instr) == 0:
                throw_syntax_error(instr_num, instr, 'Unknown opcode')
            else:
                write_file.write(write_instr[:-2] + '\n')
            
            instr_num += 1


if __name__ == "__main__":
    if len(sys.argv) == 3:
        disassemble(sys.argv[2], parse(sys.argv[1]))
    elif len(sys.argv) == 2 and sys.argv[1] == 'help':
        print('--HELP--\n', sys.argv[0], ' input_file output_file')
    else:
        print('Expecting 2 arguments for ', sys.argv[0])
