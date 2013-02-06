import json

def load(filename):
	if not filename:
		raise ValueError("filename cannot be an empty string")
	with open(filename, 'r') as f:
		d = json.load(f)
	return d

def save(filename, params):
	if not filename:
		raise ValueError("filename cannot be an empty string")
	if not isinstance(params, dict):
		raise TypeError("params must be a dict")
	if  not params:
		raise ValueError("params cannot be an empty dict")	
	with open(filename, 'w') as f:
		# extra arguments are for pretty print
		# see http://docs.python.org/2/library/json.html
		json.dump(params, f, sort_keys=True, indent=4, separators=(',', ': '))
	return filename

def to_string(params, short=False):
	if not isinstance(params, dict):
		raise TypeError("params must be a dict")
	if  not params:
		raise ValueError("params cannot be an empty dict")	
	# extra arguments are for pretty print
	# see http://docs.python.org/2/library/json.html
	if short:
		return json.dumps(params, sort_keys=True, indent=1, separators=(',', ': ')).replace("\n","").replace('"', '')
	else:
		return json.dumps(params, sort_keys=True, indent=4, separators=(',', ': '))
	
