## TODO
# invasion
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

from model import drift, selection, create_target_genome, genomes_to_nums, genome_to_num
from model import create_mutation_rates_with_modifiers as create_muation_rates
from model import create_recombination_rates_with_modifiers as create_recombination_rates
from model import create_mutation_free_population as create_population
from model import mutation_recombination
from model import hamming_fitness_genomes as create_fitness
from model import draw_environmental_changes, environmental_change

# utility functions

def make_path(filename):
	path = dirname(filename)
	if not exists(path):
		print("Creating path: %s" % path)
		makedirs(path)
	return exists(path)


## Setting up the simulation infrastructure

# time and date as a unique id
date_time = datetime.now().strftime('%Y-%b-%d_%H-%M-%S-%f')

# load parameters to global namespace
import args, params
args_and_params = args.args_and_params()
globals().update(args_and_params)
args_and_params['datetime'] = date_time
params_filename = params_dir + sep + job_name + sep + job_name + '_' + date_time + params_ext
make_path(params_filename)
params.save(params_filename, args_and_params)

# load logging
import log
log_filename = log_dir + sep + job_name + sep + job_name + '_' + date_time + log_ext
make_path(log_filename)
log.init(log_filename, console, debug)
logger = log.get_logger('simulation')

# log initial stuff
logger.info("Simulation ID: %s", date_time)
logger.info("Logging to %s", log_filename)
logger.info("Parametes from file and command line: %s", args_and_params)
logger.info("Parameters saved to file %s", params_filename)


def run(ticks=10, tick_interval=1):
	tic = clock()

	# output temporary file
	output_tmp_filename = output_dir + sep + job_name + sep + 'tmp' + sep + job_name + '_' + date_time + output_ext + '.gz'
	make_path(output_tmp_filename)
	logger.info("Saving temporary output to %s", output_tmp_filename)
	output_file = gzip.open(output_tmp_filename, 'wb')

	target_genome = create_target_genome(num_loci)
	modifiers = np.array([pi, tau, phi, rho])
	genomes = np.concatenate((target_genome, modifiers))
	genomes.resize( (1, genomes.shape[0]) )
	
	population = create_population(pop_size, genomes.shape[0])

	changes = draw_environmental_changes(ticks + 1, envch_rate, envch_start)
	
	logger.info("Starting simulation with %d ticks", ticks)
	tick = 0 # so that '--ticks=-1' will work, that is, you could start a simulation without any ticks

	for tick in range(ticks + 1):
		if changes[tick]:
			target_genome = environmental_change(target_genome, num_loci, envch_str)
		fitness, mutation_rates, recombination_rates, nums = update(genomes, target_genome, s, mu ,r)
		
		if stats_interval != 0 and tick % stats_interval == 0:
			df = tabularize(population, nums, fitness, mutation_rates, recombination_rates, tick)
			header = False if tick > 0 else True
			df.to_csv(output_file, header=header, mode='a', index_label='genome')
		
		population, genomes = step(population, genomes, target_genome, fitness, mutation_rates, recombination_rates, num_loci, nums)
		
		population, genomes = clear(population, genomes)

		if tick_interval != 0 and tick % tick_interval == 0:
			logger.debug("Tick %d", tick)

	toc = clock()
	logger.info("Simulation finished, %d ticks, time elapsed %.3f seconds",tick, (toc-tic))

	# serialization
	filename = serialize(population, genomes, target_genome)
	
	# output file
	output_file.close()
	output_filename = output_dir + sep + job_name +  sep + job_name + '_' + date_time + output_ext + '.gz'
	make_path(output_filename)
	rename(output_tmp_filename, output_filename)	
	logger.info("Saved output to %s", output_filename)

	return population, genomes, target_genome, filename


def step(population, genomes, target_genome, fitness, mutation_rates, recombination_rates, num_loci, nums):
	population = drift(population)
	population = selection(population, fitness)
	population, genomes = mutation_recombination(population, genomes, mutation_rates, recombination_rates, num_loci, target_genome, nums, rb)
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
	filename = ser_dir + sep + job_name + sep + job_name + '_' + date_time + ser_ext + '.gz'
	make_path(filename)
	fout = gzip.open(filename, "wb")
	pickle.dump((population, genomes, target_genome), fout)
	fout.close()
	logger.info("Serialized population to %s", filename)
	return filename


def tabularize(population, nums, fitness, mutation_rates, recombination_rates, tick):
	df = pd.DataFrame(data={
		'tick': pd.Series([tick] * population.shape[0], index=nums),
		'population': pd.Series(population, index=nums),
		'fitness': pd.Series(fitness, index=nums),
		'mutation_rates': pd.Series(mutation_rates, index=nums),
		'recombination_rates': pd.Series(recombination_rates, index=nums)
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
