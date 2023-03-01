import serial
import time
import random

def write_memory(address, value):
    ser.write(WRITE_CMD.to_bytes(1, 'big'))
    ser.write(address.to_bytes(3, 'big'))
    ser.write(value.to_bytes(2, 'big'))
    ser.flush()
    return ser.read(1)

def write_memory_in_bytes(address, byte_1, byte_2):
    ser.write(WRITE_CMD.to_bytes(1, 'big'))
    ser.write(address.to_bytes(3, 'big'))
    ser.write(byte_1.to_bytes(1, 'big'))
    ser.write(byte_2.to_bytes(1, 'big'))
    ser.flush()
    return ser.read(1)

def read_memory(address):
    ser.write(READ_CMD.to_bytes(1, 'big'))
    ser.write(address.to_bytes(3, 'big'))
    ser.flush()
    return ser.read(2)

def send_stop_init_cmd():
    ser.write(STOP_INIT.to_bytes(1, 'big'))
    ser.flush()
    return ser.read(1)

def check_write_ack(ack_val):
    if ack_val != ACK_CMD:
        print('Bad ACK value: ', ack_val)
        exit(1)


def random_test():
    print('STARTING RANDOM TEST\n\n')

    for i in range(100000):
        print(i)

        # generate 1-30 elements
        list_size = random.randrange(31) + 1
        write_list = []

        for i in range(list_size):
            # write random address and value
            while True:
                address = 0
                if i != 2:
                    address = random.randrange(2**24)
                    if address == 0:
                        address = 1
                if len(write_list) == 0 or ( address not in write_list[:][0] ):
                    break
                else:
                    print('REPEAT')
            value = random.randrange(65536)
            write_list.append([address, value])
            check_write_ack(write_memory(address, value))
                

        for i in range(list_size - 1, -1, -1):
            read_val = read_memory(write_list[i][0])
            read_val_int = int.from_bytes(read_val, 'big')
            if read_val_int != write_list[i][1]:
                print('RAND Error')
                print(read_val_int)
                print(write_list[i][1])
                print(i)
                print(write_list)
                exit(1)


def manual_test():
    print('STARTING MANUAL TEST\n\n')

    while True:
        print('Enter address')
        address = int(input())
        print('Enter value')
        value = int(input())

        for i in range(max(0, address - 5), min(2**24 - 1, address+5)):
            read_val = read_memory(i)
            print('%6d'% (i), '                   ', int.from_bytes(read_val, 'big'))

        read_ack = write_memory(address, value)
        print('ACK back: ' + str(read_ack))

        for i in range(max(0, address - 5), min(2**24 - 1, address+5)):
            read_val = read_memory(i)
            print('%6d'% (i), '                   ', int.from_bytes(read_val, 'big'))


def scan_test():

    print('Enter step size')
    step_size = int(input())

    print('Enter number of checks (-1 for whole memory)')
    num_checks = int(input())

    addr_lim = step_size * num_checks

    if num_checks == -1:
        addr_lim = 2**24

    print('STARTING SCAN TEST\n\n')

    for address in range(0, addr_lim, step_size):
        value = (address + 1) % 65536
        print('W - %6.6x      %5d' % (address, value))
        check_write_ack(write_memory(address, value))

    print('WRITE COMPLETE')
    print('Press ENTER to continue\n\n')
    input()

    for address in range(0, addr_lim, step_size):
        expected = (address + 1) % 65536
        val = read_memory(address)
        print('R - %6.6x      %5d' % (address, int.from_bytes(val, 'big')))

        if val != expected.to_bytes(2, 'big'):
            print('READ Error')
            print(val)
            exit(1)

    print('READ COMPLETE')
    print('Press ENTER to continue\n\n')
    input()

    print('SCAN TEST SUCCESS!')


def send_program():

    #print('Enter file name')
    #file_name = input()
    file_name = './assembler/programs/simple_image.out'
    write_vals = []

    print('Preparing to open file')

    with open(file_name, mode='rb') as file:
        file_data = list(file.read())

        print(file_data)

        print('File opened successfully with size: ', len(file_data), ' bytes')
        print('Beginning memory write')
        
        mem_address = 0
        byte_index = 0
        while byte_index < len(file_data):
            high_byte = file_data[byte_index]
            low_byte = file_data[byte_index + 1]
            print(hex(high_byte) + ',' + hex(low_byte))
            check_write_ack(write_memory_in_bytes(mem_address, high_byte, low_byte))
            write_vals.append([high_byte, low_byte])

            mem_address += 1
            byte_index += 2
        
        #for i in range(max(46336, mem_address), 65536):
        #    print(i)
        #    check_write_ack(write_memory(i, 43690))

    print('Beginning memory read')

    for i in range(len(write_vals)):
        expected_high = write_vals[i][0]
        expected_low = write_vals[i][1]

        read_bytes = list(read_memory(i))
        read_high = read_bytes[0]
        read_low = read_bytes[1]

        print(hex(read_high) + ',' + hex(read_low))

        if(read_high != expected_high or read_low != expected_low):
            print('SEND PROGRAM Error')
            print('Expected:')
            print(expected_high)
            print(expected_low)
            print('Read:')
            print(read_high)
            print(read_low)
            exit(1)
    
    print('Ending init sequence')

    check_write_ack(send_stop_init_cmd())

    print('Memory filled successfully')



WRITE_CMD = 0
READ_CMD = 1
STOP_INIT = 2
ACK_CMD = b'\x45'

print('STARTING SERIAL\n\n')

ser = serial.Serial('COM3')
ser.baudrate = 115200
ser.parity = serial.PARITY_EVEN

random.seed()

#scan_test()
#manual_test()
#random_test()
send_program()

ser.close()
