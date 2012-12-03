#import cython_load
from time import clock
import numpy as np

from model import drift, selection, create_muation_rates, create_target_genome
from model import create_recombination_rates, genomes_to_nums, genome_to_num
from model import create_fitness_by_mutational_load as create_fitness
from model import create_mutation_free_population as create_population
from model import mutation_explicit_genomes as mutation
from model import hamming_fitness_genomes as create_fitness

## Setting up the simulation infrastructure

# time and date as a unique id
import datetime
date_time = datetime.datetime.now().strftime('%Y-%b-%d_%H-%M-%S-%f')

# load parameters to global namespace
import args
args_and_params = args.args_and_params()
globals().update(args_and_params)

# load logging
import log
log.init(log_filename=log_file + '_' + date_time + log_ext, log_dir=log_dir, debug=debug)
logger = log.get_logger('simulation')
logger.info("Parametes from file and command line: %s", args_and_params)


def run(ticks=10, tick_interval=1):
	tic = clock()

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

	toc = clock()
	logger.info("Simulation finished, %d ticks, time elapsed %.3f seconds",tick, (toc-tic))
	return population, genomes


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


if __name__=="__main__":
	p,g = run(ticks, tick_interval)

