import serial
import time
import random

def write_memory(address, value):
    ser.write(WRITE_CMD.to_bytes(1, 'little'))
    ser.write(address.to_bytes(3, 'little'))
    ser.write(value.to_bytes(2, 'little'))
    ser.flush()
    return ser.read(1)

def write_memory_in_bytes(address, low, high):
    ser.write(WRITE_CMD.to_bytes(1, 'little'))
    ser.write(address.to_bytes(3, 'little'))
    ser.write(low.to_bytes(1, 'little'))
    ser.write(high.to_bytes(1, 'little'))
    ser.flush()
    return ser.read(1)

def read_memory(address):
    ser.write(READ_CMD.to_bytes(1, 'little'))
    ser.write(address.to_bytes(3, 'little'))
    ser.flush()
    return ser.read(2)

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
            write_memory(address, value)

        for i in range(list_size - 1, -1, -1):
            read_val = read_memory(write_list[i][0])
            read_val_int = int.from_bytes(read_val, 'little')
            if read_val_int != write_list[i][1]:
                print('RAND Error')
                print(read_val_int)
                print(write_list[i][1])
                print(i)
                print(write_list)
                while True:
                    pass



def manual_test():
    print('STARTING MANUAL TEST\n\n')

    while True:
        print('Enter address')
        address = int(input())
        print('Enter value')
        value = int(input())

        for i in range(max(0, address - 5), min(2**24 - 1, address+5)):
            read_val = read_memory(i)
            print('%6d'% (i), '                   ', int.from_bytes(read_val, 'little'))

        read_ack = write_memory(address, value)
        print('ACK back: ' + str(read_ack))

        for i in range(max(0, address - 5), min(2**24 - 1, address+5)):
            read_val = read_memory(i)
            print('%6d'% (i), '                   ', int.from_bytes(read_val, 'little'))


def scan_test():
    print('STARTING SCAN TEST\n\n')

    for i in range(0, 2**24, 1000):
        print('W - ' + str(i))

        address = i
        value = (i + 1) % 65536
        ack = write_memory(address, value)

        if ack != b'\x45':
            print('ACK Error')
            print(ack)
            while True:
                pass

    print('WRITE COMPLETE\n\n')
    input()

    for i in range(0, 2**24, 1000):
        address = i
        expected = (i + 1) % 65536

        val = read_memory(address)
        print(int.from_bytes(val, 'little'))

        if val != expected.to_bytes(2, 'little'):
            print('READ Error')
            print(val)
            while True:
                pass

    print('READ COMPLETE\n\n')
    input()

    print('SCAN TEST SUCCESS!')


def send_program():

    print('Enter file name')
    file_name = input()
    mem_address = 0
    write_vals = []

    with open(file_name, mode='rb') as file:
        file_data = list(file.read())

        print('File opened successfully with size: ', len(file_data), ' bytes')
        
        byte_index = 0
        while byte_index < len(file_data):
            low_byte = file_data[byte_index]
            high_byte = file_data[byte_index + 5]
            print(hex(low_byte), ',', end='')
            print(hex(high_byte))
            write_memory_in_bytes(mem_address, low_byte, high_byte)
            write_vals.append(write_vals)

            mem_address += 1
            byte_index += 10

    for i in range(mem_address):




WRITE_CMD = 0
READ_CMD = 1

print('STARTING SERIAL\n\n')

ser = serial.Serial('COM3')
ser.baudrate = 115200
ser.parity = serial.PARITY_EVEN

random.seed()

#scan_test()
manual_test()
#random_test()

ser.close()