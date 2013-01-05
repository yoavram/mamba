import os
import numpy as np

os.chdir('log')
fs = os.listdir('.')
secs = []
for f in fs:
	fin = open(f)
	for l in fin:
		if l.endswith('seconds\n'):
	               secs.append(float(l.split()[-2]))
	fin.close()
os.chdir('..')
avg = np.mean(secs)

print "Found %d simulation logs and calculated average runtime" % len(fs)
print "Average time: %.3f seconds, which are %.2f minutes" % (avg, avg/60.0)
