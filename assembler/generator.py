import sys
import random
from isa_lib import *

def generate_random(file):
    # instructions with aperture from [0, 65534]
    instr_apert_low = 0
    instr_apert_high = random.randrange(65535)

    # data with aperture from [instr_apert_high+1, 65535]
    data_apert_low = instr_apert_high + 1
    data_apert_high = 65535

    isa_list = list(isa)

    for i in range(instr_apert_low, instr_apert_high + 1):
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
                    # should prob also generate some negatives
                    new_arg = str(random.randrange(2**arg['WIDTH']))

            args_list[arg['ASM_INDEX']] = new_arg

        for arg in args_list:
            if arg != None:
                instr += arg + ', '

        file.write(instr[:-2] + '\n')

    file.write('J ' + str(random.randrange(-2**(isa['J']['ARGS'][0]['WIDTH'] - 1), 0)) + '\n')

def generate_program(type):    
    random.seed()
    with open('out.jasm', mode='w') as out:
        if type == 'random':
            generate_random(out)


if __name__ == "__main__":
    #print('Arguments count: ', len(sys.argv))
    for i, arg in enumerate(sys.argv):
        #print(f'Argument {i}: {arg}')
        if i != 0:
            generate_program(arg)
