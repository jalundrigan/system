import sys
import random
from isa_lib import *

def generate_random(write_file):
    # instruction aperture from [0, 510] or [0, 65534]
    instr_apert_low = 0
    choice = random.randrange(2)
    if choice == 0:
        instr_apert_high = random.randrange(2**9 - 1)
    elif choice == 1:
        instr_apert_high = random.randrange(65535)

    # data aperture from [instr_apert_high+1, 65535]
    data_apert_low = instr_apert_high + 1
    data_apert_high = 65535

    isa_list = list(isa)

    # keep track of where we put STI and J/BEQ/BNE/BLT/BGT instructions
    sti_list = []
    j_list = []

    i = instr_apert_low
    while i <= instr_apert_high:
        instr_name = isa_list[random.randrange(len(isa_list))]

        if i == instr_apert_high:
            # final instruction is a jump
            instr_name = 'J'
        elif instr_name == 'STD' and data_apert_low >= 2**9:
            # store direct cannot access the data aperture due to 9 bit limit
            continue
        elif instr_name == 'STI' and i >= (instr_apert_high - 4):
            # not enough space for STI
            continue
        elif instr_name == 'STI' and (  (i + 1) in j_list or 
                                        (i + 2) in j_list or 
                                        (i + 3) in j_list or 
                                        (i + 4) in j_list):
            continue

        instr = instr_name + ' '
        args_isa = isa[instr_name]['ARGS']
        args_list = len(args_isa)*[None]
        for arg in args_isa:
            new_arg = ''
            if arg['TYPE'] == None:
                continue
            elif arg['TYPE'] == 'REG':
                instr_reg = random.randrange(2**arg['WIDTH'])
                new_arg = '$' + str(instr_reg)
                if instr_name == 'STI' and arg['ASM_INDEX'] == 0:
                    # first argument of STI is destination address, ensure address is in the data aperture
                    cpp_reg = random.randrange(2**arg['WIDTH'])
                    while cpp_reg == instr_reg:
                        cpp_reg = random.randrange(2**arg['WIDTH'])
                    
                    write_file.write('LLI ' + '$' + str(cpp_reg) + ' ' + str(data_apert_low & 0xff) + '\n')
                    write_file.write('LUI ' + '$' + str(cpp_reg) + ' ' + str((data_apert_low >> 8) & 0xff) + '\n')
                    write_file.write('CPP ' + '$' + str(instr_reg) + ', $' + str(cpp_reg) + '\n')
                    # skip over STI if destination address is below data aperture low
                    write_file.write('BLT 2\n')
                    sti_list.append(i+1)
                    sti_list.append(i+2)
                    sti_list.append(i+3)
                    sti_list.append(i+4)
                    i += 4
            else:
                if instr_name == 'STD':
                    # only write in the data aperture and largest value is 2^9-1
                    new_arg = str(random.randrange(data_apert_low, min(2**9, data_apert_high + 1)))
                elif instr_name in ['BEQ', 'BNE', 'BLT', 'BGT', 'J']:
                    # don't jump out of the instruction aperture
                    jump_low = max(instr_apert_low - i, -2**(arg['WIDTH'] - 1))
                    jump_high = min(instr_apert_high - i, 2**(arg['WIDTH'] - 1) - 1)
                    jump_random = random.randrange(jump_low, jump_high + 1)
                    while (i + jump_random) in sti_list:
                        jump_random = random.randrange(jump_low, jump_high + 1)
                    j_list.append(i + jump_random)
                    new_arg = str(jump_random)
                else:
                    choice_2 = random.randrange(3)
                    if choice_2 == 0:
                        new_arg = str(random.randrange(2**arg['WIDTH']))
                    elif choice_2 == 1:
                        new_arg = hex(random.randrange(2**arg['WIDTH']))
                    elif choice_2 == 2:
                        new_arg = bin(random.randrange(2**arg['WIDTH']))
                    else:
                        print('Fatal error choice_2')
                        exit(1)

            args_list[arg['ASM_INDEX']] = new_arg

        for arg in args_list:
            if arg != None:
                instr += arg + ', '

        write_file.write(instr[:-2] + '\n')
        i += 1


def generate_program(write_file_name, program_type):    
    random.seed()
    with open(write_file_name, mode='w') as write_file:
        if program_type == 'random':
            generate_random(write_file)


if __name__ == "__main__":
    if len(sys.argv) == 3:
        generate_program(sys.argv[2], sys.argv[1])
    elif len(sys.argv) == 2 and sys.argv[1] == 'help':
        print('--HELP--\n', sys.argv[0], ' program_type output_file')
        print('Program type options: ')
        print('random')
    else:
        print('Expecting 2 arguments for ', sys.argv[0])
