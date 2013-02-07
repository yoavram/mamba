def print_underscore_version(module):
	print module.__name__, module.__version__

def print_double_version(module):
	print module.__name__, module.version.version

import os
import logging
import json
import numpy 
import pandas
import scipy
import cython

print_underscore_version(logging)
print_underscore_version(json)
print_double_version(scipy)
print_double_version(pandas)
print_double_version(numpy)
a = os.system("cython --version")