import os, os.path
import glob
import json
import params

os.chdir("output/shaw2011")
files = glob.glob("*.json")
for filename in files:
	print filename
	p = params.load(filename)
	if not 'beta' in p:
		p['beta'] = 0.0
		params.save(filename, p)
print 'done'
