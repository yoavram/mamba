from argparse import ArgumentParser, FileType
from os.path import exists
from sys import argv

import params


def create_parser():
	parser = ArgumentParser()
	parser.add_argument("--params_file",
		type=str,
		metavar="filename",
		default="params.json",
		help="parameters filename")
	parser.add_argument("--job_name",
		type=str,
		help="A general name for the simulation")
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
	parser.add_argument( "--beta",
		type=float,
		metavar="float",
		help="beneficial to deleterious mutations ratio")
	parser.add_argument( "--in_rate",
		type=float,
		metavar="float",
		help="invasion rate")
	parser.add_argument( "--in_tick",
		type=int,
		metavar="int",
		help="invasion tick")
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
	parser.add_argument( "--in_pi",
		type=int,
		metavar="int",
		help="invader hypermutaion threshold")
	parser.add_argument( "--in_tau",
		type=float,
		metavar="float",
		help="invader hypermutaion rate increase")
	parser.add_argument( "--in_phi",
		type=int,
		metavar="int",
		help="invader hyper-recombination threshold")
	parser.add_argument( "--in_rho",
		type=float,
		metavar="float",
		help="invader hyper-recombination rate increase")
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
		help="NOT IMPLEMENTED use recombination barriers") # TODO remove NOT IMPLEMENTED?
	parser.add_argument( "--neutral",
		action='store_true',
		default=False,
		help="one neutral site") # TODO remove NOT IMPLEMENTED?
	parser.add_argument( "--debug",
		action='store_false',
		default=True,
		help="production mode"),
	parser.add_argument( "--adapt",
		action='store_true',
		default=False,
		help="run until population has adapted")
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
	if isinstance(arg, str) or isinstance(arg, unicode):
		return "'"+arg+"'"
	else:
		return str(arg)


def args_and_params():	
	n_args = len(argv)
	if n_args == 2 and not argv[1].startswith('-'):
		parameters = params.load(argv[1])
	else:	
		args = parse_args(create_parser())
		parameters = params.load(args.params_file)
		args = vars(args)
		args = { k: v for k,v in args.items() if v != None }
		parameters.update(args)
	# this is a workaround for sumatra bug (https://groups.google.com/forum/?fromgroups=#!topic/sumatra-users/OIuBWxJF_W0)
	string_to_boolean(parameters,'console')
	string_to_boolean(parameters,'debug')
	string_to_boolean(parameters,'rb')
	string_to_boolean(parameters,'neutral')
	string_to_boolean(parameters,'envch_start')
	return parameters

def string_to_boolean(parameters, field):
	if field in parameters and (isinstance(parameters[field], unicode) or isinstance(parameters[field], str)):
		parameters[field] = parameters[field].lower() == 'true'

if __name__ == '__main__':
	d = args_and_params()
	print params.to_string(d)
