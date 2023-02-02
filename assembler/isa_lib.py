REG_WIDTH = 4

isa = {
    'LDD' : {
                'OPCODE' : '000',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 9,
                                'ASM_INDEX' : 1
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'J' :   {
                'OPCODE' : '001',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 13,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'STD' : {
                'OPCODE' : '010',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 9,
                                'ASM_INDEX' : 0
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1
                            }
                         ]   
            },
    'LLI' : {
                'OPCODE' : '0110',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 8,
                                'ASM_INDEX' : 1
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'LUI' : {
                'OPCODE' : '0111',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 8,
                                'ASM_INDEX' : 1
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'BEQ' : {
                'OPCODE' : '10000',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 11,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'BNE' : {
                'OPCODE' : '10001',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 11,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'BLT' : {
                'OPCODE' : '10010',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 11,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'BGT' : {
                'OPCODE' : '10011',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 11,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'ADDI' : {
                'OPCODE' : '101',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 9,
                                'ASM_INDEX' : 1
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'SUBI' : {
                'OPCODE' : '110',
                'ARGS' : [
                            {
                                'TYPE' : 'LIT',
                                'WIDTH' : 9,
                                'ASM_INDEX' : 1
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'ADD' : {
                'OPCODE' : '11100000',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'SUB' : {
                'OPCODE' : '11100001',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'MUL' : {
                'OPCODE' : '11100010',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'AND' : {
                'OPCODE' : '11100011',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'OR' : {
                'OPCODE' : '11100100',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'XOR' : {
                'OPCODE' : '11100101',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'CMP1' : {
                'OPCODE' : '11100110',
                'ARGS' : [
                            {
                                'TYPE' : None,
                                'WIDTH' : 4,
                                'ASM_INDEX' : None
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'CMP2' : {
                'OPCODE' : '11100111',
                'ARGS' : [
                            {
                                'TYPE' : None,
                                'WIDTH' : 4,
                                'ASM_INDEX' : None
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'CPP' : {
                'OPCODE' : '11101000',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1
                            }
                         ]   
            },
    'LDN' : {
                'OPCODE' : '11110000',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
    'STI' : {
                'OPCODE' : '11110001',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1
                            }
                         ]   
            },
    'MOV' : {
                'OPCODE' : '11110010',
                'ARGS' : [
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 1
                            },
                            {
                                'TYPE' : 'REG',
                                'WIDTH' : REG_WIDTH,
                                'ASM_INDEX' : 0
                            }
                         ]   
            },
}