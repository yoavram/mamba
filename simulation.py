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

def run(ticks=10, tick_interval=1, debug=False):
	tic = clock()

	target_genome = create_target_genome(num_loci)
	genomes = target_genome.copy()
	genomes.resize( (1, target_genome.shape[0]) )

	population = create_population(pop_size, genomes.shape[0])

	fitness = create_fitness(genomes, target_genome, s)
	mutation_rates = create_muation_rates(mu, genomes.shape[0])
	recombination_rates = create_recombination_rates(r, genomes.shape[0])

	print "Starting simulation with ", ticks, "ticks"
	for tick in range(ticks + 1):
		if debug: print "Drift"
		population = drift(population)
		if debug: print "Selection"
		population = selection(population, fitness)
		if debug: print "Mutation"
		population, genomes = mutation(population, genomes, mutation_rates, num_loci, target_genome)
		if debug: print "Update"
		fitness = create_fitness(genomes, target_genome, s)
		mutation_rates = create_muation_rates(mu, genomes.shape[0])
		recombination_rates = create_recombination_rates(r, genomes.shape[0])
		if debug: print "Clear"
		population, genomes, fitness, mutation_rates, recombination_rates = clear_empty_classes(population, genomes, fitness, mutation_rates, recombination_rates)
		if debug: print "Done"
		
		if tick_interval != 0 and tick % tick_interval == 0:
			print "Tick", tick
	toc = clock()
	print "Simulation finished,", tick, "ticks, time elapsed", (toc-tic), "seconds"
	return population, genomes

if __name__=="__main__":
	p,g = run(10,1,True)

