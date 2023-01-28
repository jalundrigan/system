print('starting')

with open('tester.jasm', mode='r') as read_file:
    with open('out', mode='wb') as write_file:
        
        for line in read_file:
            print(line)
    

print('stopping')