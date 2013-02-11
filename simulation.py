## TODO
# realtime plotting?
# recombination barriers

from time import clock
from os import makedirs, rename
from os.path import sep, exists, dirname
from datetime import datetime
import pickle
import gzip

import pandas as pd
import numpy as np

from model import drift, selection, create_target_genome
from model import create_mutation_rates_with_modifiers as create_muation_rates
from model import create_recombination_rates_with_modifiers as create_recombination_rates
from model import create_mutation_free_population as create_population
from model import mutation_recombination
from model import hamming_fitness_genomes as create_fitness
from model import genomes_to_nums_w_mods as genomes_to_nums
#from model import genomes_to_nums
from model import draw_environmental_changes, environmental_change, invasion

# utility functions

def make_path(filename):
	path = dirname(filename)
	if not exists(path):
		print("Creating path: %s" % path)
		makedirs(path)
	return exists(path)


def cat_file_path(extension):
	return output_dir + sep + job_name + sep + sumatra_label + extension

## Setting up the simulation infrastructure

# load parameters to global namespace
import args, params
args_and_params = args.args_and_params()
if not 'sumatra_label' in args_and_params:
	args_and_params['sumatra_label'] = datetime.now().strftime('%Y-%b-%d_%H-%M-%S-%f')
globals().update(args_and_params)
params_filename = cat_file_path(params_ext)
make_path(params_filename)
params.save(params_filename, args_and_params)

# load logging
import log
log_filename = cat_file_path(log_ext)
make_path(log_filename)
log.init(log_filename, console, debug)
logger = log.get_logger('simulation')

# log initial stuff
logger.info("Simulation ID: %s", sumatra_label)
logger.info("Logging to %s", log_filename)
logger.info("Parametes from file and command line: %s", params.to_string(args_and_params, short=True))
logger.info("Parameters saved to file %s", params_filename)


def run(ticks=10, tick_interval=1):
	tic = clock()

	# output temporary file
	output_tmp_filename = cat_file_path('.tmp' + output_ext + '.gz')
	make_path(output_tmp_filename)
	logger.info("Saving temporary output to %s", output_tmp_filename)
	output_file = gzip.open(output_tmp_filename, 'wb')

	# init population
	target_genome = create_target_genome(num_loci)
	modifiers = np.array([pi, tau, phi, rho])
	genomes = np.concatenate((target_genome, modifiers))
	genomes.resize( (1, genomes.shape[0]) )
	
	population = create_population(pop_size, genomes.shape[0])

	changes = draw_environmental_changes(ticks + 1, envch_rate, envch_start)
	logger.debug("Number of environmental changes is %d" % changes.sum())
	
	logger.info("Starting simulation with %d ticks", ticks)
	tick = 0 # so that '--ticks=-1' will work, that is, you could start a simulation without any ticks

	for tick in range(ticks + 1):
		if changes[tick]:
			target_genome = environmental_change(target_genome, num_loci, envch_str)
		fitness, mutation_rates, recombination_rates, nums = update(genomes, target_genome, s, mu ,r)
		if stats_interval != 0 and tick % stats_interval == 0:
			df = tabularize(population, nums, fitness, mutation_rates, recombination_rates, tick)
			header = False if tick > 0 else True
			df.to_csv(output_file, header=header, mode='a', index_label='index')
		
		population, genomes = step(population, genomes, target_genome, fitness, mutation_rates, recombination_rates, num_loci, nums)
		
		population, genomes = clear(population, genomes)

		if tick_interval != 0 and tick % tick_interval == 0:
			logger.debug("Tick %d", tick)
		if in_tick == tick and in_rate > 0:
			logger.debug("Invading resident population")
			modifiers = [in_pi, in_tau, in_phi, in_rho]
			population, genomes = invasion(population, genomes, modifiers, in_rate, num_loci)

	toc = clock()
	logger.info("Simulation finished, %d ticks, time elapsed %.3f seconds",tick, (toc-tic))

	# serialization
	filename = serialize(population, genomes, target_genome)
	
	# output file
	output_file.close()
	output_filename = cat_file_path(output_ext + '.gz')
	make_path(output_filename)
	rename(output_tmp_filename, output_filename)
	logger.info("Saved output to %s", output_filename)
	
	return population, genomes, target_genome, filename


def step(population, genomes, target_genome, fitness, mutation_rates, recombination_rates, num_loci, nums):
	population = drift(population)
	population = selection(population, fitness)
	population, genomes = mutation_recombination(population, genomes, mutation_rates, recombination_rates, num_loci, target_genome, nums, beta, rb)
	return population, genomes


def update(genomes, target_genome, s, mu ,r):
	fitness = create_fitness(genomes, target_genome, s, num_loci)
	mutation_rates = create_muation_rates(mu, genomes, fitness, s, num_loci)
	recombination_rates = create_recombination_rates(r, genomes, fitness, s, num_loci)
	nums = genomes_to_nums(genomes, num_loci)
	return fitness, mutation_rates, recombination_rates, nums


def clear(population, genomes):
	non_zero = population > 0
	population = population[non_zero]
	genomes = genomes[non_zero]
	return population, genomes


def serialize(population, genomes, target_genome):
	filename = cat_file_path(ser_ext + '.gz')
	make_path(filename)
	fout = gzip.open(filename, "wb")
	pickle.dump((population, genomes, target_genome), fout)
	fout.close()
	logger.info("Serialized population to %s", filename)
	return filename


def array_to_str(num):
	return ' '.join(map(str, num))

def tabularize(population, nums, fitness, mutation_rates, recombination_rates, tick):
	df = pd.DataFrame(data={
		'genome': pd.Series([array_to_str(n[:-4]) for n in nums]),
		'pi': pd.Series([n[-4] for n in nums]),
		'tau': pd.Series([n[-3] for n in nums]),
		'phi': pd.Series([n[-2] for n in nums]),
		'rho': pd.Series([n[-1] for n in nums]),
		'tick': pd.Series([tick] * population.shape[0]),
		'population': pd.Series(population),
		'fitness': pd.Series(fitness),
		'mutation_rates': pd.Series(mutation_rates),
		'recombination_rates': pd.Series(recombination_rates)
		})
	return df

def deserialize(filename):
	fin = open(filename)
	pickled = pickle.load(fin)
	fin.close()
	logger.info("Deserialized population from %s", filename)
	return pickled


if __name__=="__main__":
	p, g, tg, f = run(ticks, tick_interval)
