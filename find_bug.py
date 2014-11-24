import glob
files=glob.glob("invasion.o*")
for fn in files:
	f = open(fn)
	lines=f.readlines()
	if len(lines)>2:
		print fn
	f.close()
