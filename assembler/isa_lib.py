REG_WIDTH = 4

isa = {
    'LDD' : {
                'OPCODE' : '000',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 9,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'J' :   {
                'OPCODE' : '001',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 13,
                                'ASM_INDEX' : 0,
                                'SIGNED' : True
                            }
                         ]   
            },
    'STD' : {
                'OPCODE' : '010',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 9,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            }
                         ]   
            },
    'LLI' : {
                'OPCODE' : '0110',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 8,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'LUI' : {
                'OPCODE' : '0111',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 8,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'BEQ' : {
                'OPCODE' : '10000',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 11,
                                'ASM_INDEX' : 0,
                                'SIGNED' : True
                            }
                         ]   
            },
    'BNE' : {
                'OPCODE' : '10001',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 11,
                                'ASM_INDEX' : 0,
                                'SIGNED' : True
                            }
                         ]   
            },
    'BLT' : {
                'OPCODE' : '10010',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 11,
                                'ASM_INDEX' : 0,
                                'SIGNED' : True
                            }
                         ]   
            },
    'BGT' : {
                'OPCODE' : '10011',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 11,
                                'ASM_INDEX' : 0,
                                'SIGNED' : True
                            }
                         ]   
            },
    'ADDI' : {
                'OPCODE' : '101',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 9,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'SUBI' : {
                'OPCODE' : '110',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 9,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'ADD' : {
                'OPCODE' : '11100000',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'SUB' : {
                'OPCODE' : '11100001',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'MUL' : {
                'OPCODE' : '11100010',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'AND' : {
                'OPCODE' : '11100011',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'OR' : {
                'OPCODE' : '11100100',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'XOR' : {
                'OPCODE' : '11100101',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'CMP1' : {
                'OPCODE' : '11100110',
                'ARGS' : [
                            {
                                'TYPE' : None,
                                'WIDTH' : 4,
                                'ASM_INDEX' : None,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'CMP2' : {
                'OPCODE' : '11100111',
                'ARGS' : [
                            {
                                'TYPE' : None,
                                'WIDTH' : 4,
                                'ASM_INDEX' : None,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'CPP' : {
                'OPCODE' : '11101000',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            }
                         ]   
            },
    'LDN' : {
                'OPCODE' : '11110000',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
    'STI' : {
                'OPCODE' : '11110001',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            }
                         ]   
            },
    'MOV' : {
                'OPCODE' : '11110010',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1,
                                'SIGNED' : False
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0,
                                'SIGNED' : False
                            }
                         ]   
            },
}