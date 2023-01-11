print('starting')

with open('out', mode='rb') as file:
    read_data = list(file.read())
    
    i = 0
    while i < len(read_data):
        print(hex(read_data[i]), ',', end='')
        print(hex(read_data[i + 5]))
        i += 10


print('stopping')