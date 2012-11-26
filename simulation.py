# import numpy as np
# import pyximport
# pyximport.install(setup_args={"script_args":["--compiler=mingw32"],
#                               "include_dirs":np.get_include()},
#                   reload_support=True)
import cython_load
from time import clock
import numpy as np

from params import *

from model import drift, selection, create_muation_rates, create_target_genome, clear_empty_classes, create_recombination_rates
from model import create_fitness_by_mutational_load as create_fitness
from model import create_mutation_free_population as create_population
from model import mutation_implicit_genomes as mutation
#from model_c import mutation_by_mutation_load as mutation
from model_c import hamming_fitness_genomes as create_fitness

def run(ticks=1000, tick_interval=100):
	tic = clock()

	target_genome = create_target_genome(num_loci)
	genomes = target_genome.copy()
	genomes.resize( (1, target_genome.shape[0]) )
	genome2 = target_genome.copy()
	genome2[0] = 1
	genomes = np.vstack((genomes, genome2))

	population = create_population(pop_size, genomes.shape[0])
	population[1], population[0] = population[0]/2, population[0]/2
	fitness = create_fitness(genomes, target_genome, s)
	mutation_rates = create_muation_rates(mu, genomes.shape[0])
	recombination_rates = create_recombination_rates(r, genomes.shape[0])

	print "Starting simulation with ", ticks, "ticks"
	for tick in range(ticks + 1):
		drift(population)
		selection(population, fitness)
		population, genomes = mutation(population, genomes, mutation_rates, num_loci, target_genome)
		fitness = create_fitness(genomes, target_genome, s)
		mutation_rates = create_muation_rates(mu, genomes.shape[0])
		recombination_rates = create_recombination_rates(r, genomes.shape[0])
		population, genomes, fitness, mutation_rates, recombination_rates = clear_empty_classes(population, genomes, fitness, mutation_rates, recombination_rates)

		if tick_interval != 0 and tick % tick_interval == 0:
			print "Tick", tick
	toc = clock()
	print "Simulation finished,", tick, "ticks, time elapsed", (toc-tic), "seconds"
	return population, genomes

if __name__=="__main__":
	p = run(100)

