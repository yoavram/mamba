from argparse import ArgumentParser, FileType
from os.path import exists

def create_parser():
	parser = ArgumentParser()
	parser.add_argument("--params",
		type=str,
		metavar="filename",
		default="params.py",
		help="parameters filename")
	parser.add_argument("--log_file",
		type=str,
		metavar="filename",
		help="log filename")
	parser.add_argument("--pop_size",
		type=int,
		metavar="integer",
		help="population size")
	parser.add_argument( "--mu",
		type=float,
		metavar="float",
		help="mutation rate")
	parser.add_argument( "--r",
		type=float,
		metavar="float",
		help="recombination rate")
	parser.add_argument( "--ticks",
		type=int,
		metavar="integer",
		help="number of ticks")
	parser.add_argument( "--num_loci",
		type=int,
		metavar="integer",
		help="number of loci")
	parser.add_argument( "--s",
		type=float,
		metavar="float",
		help="selection coefficient")
	parser.add_argument( "--debug",
		type=bool,
		metavar="boolean",
		help="debug mode")
	parser.add_argument( "--tick_interval",
		type=int,
		metavar="integer",
		help="logging tick interval, 0 for no logging")
	return parser


def parse_args(parser):
	args = parser.parse_args()
	return args


def load_params_file(filename):
	params = {}
	if filename and exists(filename):
		fin = open(filename)
		for line in fin:
			k,v = line.split('=')
			k,v = k.strip(), eval(v.strip())
			params[k] = v
		fin.close()
	return params


def args_and_params():	
	args = parse_args(create_parser())
	params = load_params_file(args.params)
	args = vars(args)
	args = { k: v for k,v in args.items() if v != None }
	params.update(args)
	print params
	return params

if __name__ == '__main__':
	args_and_params()
