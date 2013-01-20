from argparse import ArgumentParser, FileType
from os.path import exists, sep, dirname
from datetime import datetime

import params


def create_parser():
	parser = ArgumentParser()
	parser.add_argument("--params_file",
		type=str,
		metavar="filename",
		default="params.json",
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
	parser.add_argument( "--pi",
		type=int,
		metavar="int",
		help="hypermutaion threshold")
	parser.add_argument( "--tau",
		type=float,
		metavar="float",
		help="hypermutaion rate increase")
	parser.add_argument( "--phi",
		type=int,
		metavar="int",
		help="hyper-recombination threshold")
	parser.add_argument( "--rho",
		type=float,
		metavar="float",
		help="hyper-recombination rate increase")
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
	parser.add_argument( "--envch_rate",
		type=float,
		metavar="float",
		help="environmental change rate")
	parser.add_argument( "--envch_str",
		type=int,
		metavar="int",
		help="environmental change strength")
	parser.add_argument( "--envch_start",
		action='store_true',
		default=False,
		help="change environment on startup")
	parser.add_argument( "--rb",
		action='store_true',
		default=False,
		help="use recombination barriers")
	parser.add_argument( "--debug",
		action='store_false',
		default=True,
		help="production mode"),
	parser.add_argument( "--console",
		action='store_false',
		default=True,
		help="don't output logging to console")
	parser.add_argument( "--tick_interval",
		type=int,
		metavar="integer",
		help="logging tick interval, 0 for no logging")
	parser.add_argument( "--stats_interval",
		type=int,
		metavar="integer",
		help="statistics gathering tick interval, 0 for no statistics gathering")
	return parser


def parse_args(parser):
	args = parser.parse_args()
	return args


def str2(arg):
	if isinstance(arg, str):
		return "'"+arg+"'"
	else:
		return str(arg)


def make_path(filename):
	path = dirname(filename)
	if not exists(path):
		print("Creating path: %s" % path)
		makedirs(path)
	return exists(path)


def args_and_params():	
	args = parse_args(create_parser())
	parameters = params.load(args.params_file)
	args = vars(args)
	args = { k: v for k,v in args.items() if v != None }
	parameters.update(args)
	# time and date as a unique id
	date_time = datetime.now().strftime('%Y-%b-%d_%H-%M-%S-%f')
	parameters['date_time'] = date_time
	return parameters


def create_params_file(p):
	params_filename = p['params_dir'] + sep + p['job_name'] + sep + p['job_name'] + '_' + p['date_time'] + p['params_ext']
	make_path(params_filename)
	return params.save(params_filename, p)

if __name__ == '__main__':
	p = args_and_params()
	print create_params_file(p)
