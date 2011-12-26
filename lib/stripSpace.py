import sys

f = open(sys.argv[1],"r")

lines = []

for line in f.readlines():
	line = line.strip()
	if line != '':
		lines.append(line)

f.close()

f = open(sys.argv[1],"w")
for line in lines:
	f.write(line+"\n")
