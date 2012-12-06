## TODO
# modifiers
# recombination
# statistics
# invasion
# realtime plotting?
# sumatra interface?

#import cython_load
from time import clock
from os.path import sep
from datetime import datetime
import pickle
import pandas as pd

import numpy as np

from model import drift, selection, create_muation_rates, create_target_genome
from model import create_recombination_rates, genomes_to_nums, genome_to_num
from model import create_fitness_by_mutational_load as create_fitness
from model import create_mutation_free_population as create_population
from model import mutation_explicit_genomes as mutation
from model import hamming_fitness_genomes as create_fitness

## Setting up the simulation infrastructure

# time and date as a unique id
date_time = datetime.now().strftime('%Y-%b-%d_%H-%M-%S-%f')

# load parameters to global namespace
import args
args_and_params = args.args_and_params()
globals().update(args_and_params)
params_filename = params_dir + sep + job_name + '_' + date_time + params_ext
args.save_params_file(params_filename, args_and_params)

# load logging
import log
log_filename = log_dir + sep + job_name + '_' + date_time + log_ext
log.init(log_filename, console)
logger = log.get_logger('simulation')

# log initial stuff
logger.info("Simulation ID: %s", date_time)
logger.info("Logging to %s", log_filename)
logger.info("Parametes from file and command line: %s", args_and_params)
logger.info("Parameters saved to file %s", params_filename)


def run(ticks=10, tick_interval=1):
	tic = clock()
	stats = []

	target_genome = create_target_genome(num_loci)
	genomes = target_genome.copy()
	genomes.resize( (1, target_genome.shape[0]) )

	population = create_population(pop_size, genomes.shape[0])

	logger.info("Starting simulation with %d ticks", ticks)
	for tick in range(ticks + 1):
		fitness, mutation_rates, recombination_rates, nums = update(genomes, target_genome, s, mu ,r)

		population, genomes = step(population, genomes, target_genome, fitness, mutation_rates, recombination_rates, num_loci, nums)
		
		population, genomes = clear(population, genomes)

		if tick_interval != 0 and tick % tick_interval == 0:
			logger.debug("Tick %d", tick)
		if stats_interval !=0 and tick % stats_interval == 0:
			stats.append(tabularize(population, nums, fitness, mutation_rates, recombination_rates))

	toc = clock()
	logger.info("Simulation finished, %d ticks, time elapsed %.3f seconds",tick, (toc-tic))
	return population, genomes, target_genome, stats


def step(population, genomes, target_genome, fitness, mutation_rates, recombination_rates, num_loci, nums):
	population = drift(population)
	population = selection(population, fitness)
	population, genomes = mutation(population, genomes, mutation_rates, num_loci, target_genome, nums)
	return population, genomes


def update(genomes, target_genome, s, mu ,r):
	fitness = create_fitness(genomes, target_genome, s)
	mutation_rates = create_muation_rates(mu, genomes.shape[0])
	recombination_rates = create_recombination_rates(r, genomes.shape[0])
	nums = genomes_to_nums(genomes)
	return fitness, mutation_rates, recombination_rates, nums

def clear(population, genomes):
	non_zero = population > 0
	population = population[non_zero]
	genomes = genomes[non_zero]
	return population, genomes


def serialize(population, genomes, target_genome):
	filename = ser_dir + sep + job_name + '_' + date_time + ser_ext
	fout = open(filename, "wb")
	pickle.dump((population, genomes, target_genome), fout)
	fout.close()
	logger.info("Serialized population to %s", filename)
	return filename


def tabularize(population, nums, fitness, mutation_rates, recombination_rates):
	df = pd.DataFrame(data={
		'tick''population': pd.Series(population),
		'fitness': pd.Series(fitness),
		'mutation_rates': pd.Series(mutation_rates),
		'recombination_rates': pd.Series(recombination_rates)
		}, 
		index=nums)
	return df

def deserialize(filename):
	fin = open(filename)
	pickled = pickle.load(fin)
	fin.close()
	logger.info("Deserialized population from %s", filename)
	return pickled


if __name__=="__main__":
	p, g, tg, stats = run(0, tick_interval)
