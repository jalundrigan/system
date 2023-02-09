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

    i = instr_apert_low
    while i <= instr_apert_high:
        instr_name = isa_list[random.randrange(len(isa_list))]

        if instr_name == 'STI' or (instr_name == 'STD' and data_apert_low >= 2**9):
            # store direct cannot access the data aperture due to 9 bit limit
            continue

        instr = instr_name + ' '
        args_isa = isa[instr_name]['ARGS']
        args_list = len(args_isa)*[None]
        for arg in args_isa:
            new_arg = ''
            if arg['TYPE'] == None:
                continue
            elif arg['TYPE'] == 'REG':
                new_arg = '$' + str(random.randrange(2**arg['WIDTH']))
            else:
                if instr_name == 'STD':
                    # only write in the data aperture and largest value is 2^9-1
                    new_arg = str(random.randrange(data_apert_low, min(2**9, data_apert_high + 1)))
                elif instr_name in ['BEQ', 'BNE', 'BLT', 'BGT', 'J']:
                    # don't jump out of the instruction aperture
                    jump_low = max(instr_apert_low - i, -2**(arg['WIDTH'] - 1))
                    jump_high = min(instr_apert_high - i, 2**(arg['WIDTH'] - 1) - 1)
                    new_arg = str(random.randrange(jump_low, jump_high + 1))
                else:
                    new_arg = str(random.randrange(2**arg['WIDTH']))

            args_list[arg['ASM_INDEX']] = new_arg

        for arg in args_list:
            if arg != None:
                instr += arg + ', '

        write_file.write(instr[:-2] + '\n')
        i += 1

    jump_low = max(instr_apert_low - instr_apert_high, -2**(isa['J']['ARGS'][0]['WIDTH'] - 1))
    write_file.write('J ' + str(random.randrange(jump_low, 0)) + '\n')


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
