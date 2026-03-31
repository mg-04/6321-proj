# Comment out the set_ideal_network in sdc file
# Need to use this sdc file in apr
import sys
top = sys.argv[1]

def comment_lines(input_file, out_file):
    with open(input_file, 'r') as file:
        lines = file.readlines()

    with open(out_file, 'w') as file:
        for line in lines:
            if line.startswith('set_ideal_network'):
                file.write(f'# {line}')
            else:
                file.write(line)

comment_lines(f'{top}.syn.sdc', f'{top}.syn.mod.sdc')
