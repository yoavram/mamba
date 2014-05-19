import pandas as pd
import gzip
import json
import glob
import os
import time

os.chdir("output/adaptation")
files = glob.glob("*.json")
print "%d files to process in %s" %(len(files), os.getcwd())
file_dicts = []
for fname in files:
	with open(fname) as f:
		file_dicts.append(json.load(f))
print "%d files processes successfuly" % len(file_dicts)
df = pd.DataFrame(file_dicts)
os.chdir("..")
fname = "invasion_%s.csv.gz" % time.strftime("%d_%m_%Y")
with gzip.open(fname, "w") as f:
	df.to_csv(f)
print "Saved to %s" % fname
os.chdir("..")
