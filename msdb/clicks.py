import gzip
import pandas as pd
import numpy as np
import json
import csv
import glob
import time

tic = time.time()
fields = [u'beta', u'console', u'debug', u'envch_rate', u'envch_start', u'envch_str', u'in_phi', u'in_pi', u'in_rate', u'in_rho', u'in_tau', u'in_tick', u'job_name', u'log_dir', u'log_ext', u'mu', u'num_loci', u'output_dir', u'output_ext', u'params_dir', u'params_ext', u'params_file', u'phi', u'pi', u'pop_size', u'r', u'rb', u'rho', u's', u'ser_dir', u'ser_ext', u'stats_interval', u'sumatra_label', u'tau', u'tick_interval', u'ticks',  'tick5', 'tick10', 'tick8', 'tick9', 'tick1', 'tick2', 'tick3', 'tick4', 'tick6', 'tick7']
gf = gzip.open("clicks.csv.gz", 'wb')
wr = csv.DictWriter(gf, sorted(fields))
wr.writeheader()
print "Writing to clicks.csv.gz"

for filename in glob.glob("/groups/lilach_hadany/yoavram/workspace/mamba/output/shaw2011/*.csv.gz"):
	if "tmp" in filename:
		continue
	print filename
	with open(filename[:-6] + 'json') as f:
		d = json.load(f)

	s = d['s']
	try:
		with gzip.open(filename) as f:
			df = pd.read_csv(f)
	except IOError as e:
		print "I/O error({0}): {1}".format(e.errno, e.strerror)
		continue

	ddf = df[['tick','fitness']]
	ddf = ddf.groupby('tick').aggregate(np.max).reset_index()

	i = 0
	m = 0 
	ticks = {}
	while i < len(ddf) and m < 10:
		if ddf['fitness'][i] < (1-s)**m:
			m += 1
			ticks['tick' + str(m)] = ddf['tick'][i]
		else:
			i += 1
		
	d.update(ticks)
	wr.writerow(d)

print "Finished, saving to clicks.csv.gz"
gf.close()

toc = time.time()
print "%f seconds elapsed" % (toc-tic)
