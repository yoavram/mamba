import numpy as np
import numpy.random as npr
import random
from math import floor
import cython_load
from model_c import find_row

# TODO see where range can be chaged to arange and arange to xrange (generator) http://www.jesshamrick.com/2012/04/29/the-demise-of-for-loops/
# TODO sparse matrix?


def create_uniform_mutation_load_population(pop_size, num_classes):
	return npr.multinomial(pop_size, [1.0 / num_classes] * num_classes)


def create_mutation_free_population(pop_size, num_classes):
	population = np.zeros(num_classes, dtype=np.int)
	population[0] = pop_size
	return population


def create_fitness_by_mutational_load(s, num_classes):
	return np.array([(1 - s) ** x for x in range(num_classes)])


def create_muation_rates(mu, num_classes):
	return np.array([mu] * num_classes)


def create_recombination_rates(r, num_classes):
	return np.array([r] * num_classes)


def create_target_genome(num_loci):
	return np.array(np.zeros(num_loci), dtype=np.int)


def hamming_fitness_genome(genome, target_genome, s):
	# TODO np.hamming
	return s ** (genome != target_genome).sum()


def hamming_fitness_genomes(genomes, target_genome, s):
	'''The cython version is faster'''
	# TODO check np.vectorize
	return np.apply_along_axis(hamming_fitness_genome, 1, genomes, target_genome, s)


def genome_to_num(genome):
	i = np.arange(genome.shape[0])
	return (2. ** i * genome).sum()


def drift(population):
	pop_size = population.sum()
	p = population / float(pop_size)
	population[:] = npr.multinomial(pop_size, p)
	return population


def selection(population, fitness):
	pop_size = population.sum()
	p = population * fitness
	p[:] = p / p.sum()
	population[:] = npr.multinomial(pop_size, p)
	return population


def draw_environmental_changes(ticks, env_change_prob):
	changes = npr.binomial(n=1, p=env_change_prob, size=ticks)
	return changes


def environmental_change(target_genome):
  changed_loci = choose(num_loci, num_loci_to_change)
  target_genome[changed_loci] = (target.genome[changed.loci] + 1) % 2


def choose(n, k):
    return random.sample(xrange(n), k)   


def mutation_explicit_genomes(population, genomes, mutation_rates, num_loci, target_genome):
	'''limit to one mutation per individual, doesn't update rates or fitness'''
	mutations = np.random.poisson(population * mutation_rates, size=population.shape)	
	loci = npr.randint(0, num_loci, mutations.sum())
	loci_split = np.split(loci, mutations.cumsum())[:-1]
	new_alleles = (target_genome[loci] + 1) % 2
	new_allele_index = 0
	# create dict of new strains
	new_counts = {}
	new_genomes = {}
	for strain in range(len(loci_split)):
		population[strain] = population[strain] - mutations[strain]
		assert population[strain] >= 0  # ASSERT
		for locus in loci_split[strain]:
			new_allele = new_alleles[new_allele_index]
			new_allele_index += 1
			key = (strain, locus, new_allele)
			if key in new_counts:
				new_counts[key] += 1
			else:
				new_genome = genomes[strain,:].copy()				
				new_genome[locus] = new_allele
				index = find_row(genomes, new_genome)
				if index == -1:
					new_counts[key] = 1
					new_genomes[key] = new_genome
				else:
					population[index] += 1
	# update 
	if len(new_counts) > 0:
		population = np.append(population, new_counts.values())
		genomes = np.vstack((genomes, new_genomes.values()))
	return population, genomes


def clear_empty_classes(population, genomes, fitness, mutation_rates, recombination_rates):
	non_zero = population > 0
	population = population[non_zero]
	fitness = fitness[non_zero]
	mutation_rates = mutation_rates[non_zero]
	recombination_rates = recombination_rates[non_zero]
	genomes = genomes[non_zero]
	return population, genomes, fitness, mutation_rates, recombination_rates

