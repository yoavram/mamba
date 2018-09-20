import json
import csv
import os
import gzip
from tqdm import tqdm

for entry in os.scandir('output/neutral'):
	if entry.path.endswith('json'):
		break
with open(entry.path) as f:
	data = json.load(f)
fieldnames = list(data.keys())

with open('summary.csv', 'w') as outfile:
	writer = csv.DictWriter(outfile, fieldnames=fieldnames)
	writer.writeheader()

	for entry in tqdm(os.scandir('output/neutral')):
		if not entry.path.endswith('json'):
			continue
		with open(entry.path) as f:
			data = json.load(f)
		writer.writerow(data)