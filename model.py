import numpy as np
import numpy.random as npr
import random
from math import floor
from scipy.spatial.distance import cdist, hamming

# TODO see where range can be chaged to arange and arange to xrange (generator) http://www.jesshamrick.com/2012/04/29/the-demise-of-for-loops/

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
	load = hamming(genome, target_genome) * target_genome.shape[0]
	return s ** load


def hamming_fitness_genomes(genomes, target_genome, s):
	num_loci = target_genome.shape[0]
	load = cdist(genomes, target_genome.reshape(1, num_loci), 'hamming') * num_loci
	return (s ** load).reshape(genomes.shape[0])


def genome_to_num(genome):
    non_zero = genome.nonzero()[0]
    return (2. ** non_zero).sum() # this is faster than numexpr


def genomes_to_nums(genomes):
    return np.array([genome_to_num(g) for g in genomes])


def find_row_nums(nums, target):
	# cython version is slightly faster
	for i,n in enumerate(nums):
		if n == target:
			return i
	return -1


def drift(population):
	pop_size = population.sum()
	p = population / float(pop_size)
	population[:] = npr.multinomial(pop_size, p)
	return population


def selection(population, fitness):
	pop_size = population.sum
	p = population * fitness.reshape(population.shape)
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


def mutation_explicit_genomes(population, genomes, mutation_rates, num_loci, target_genome, nums):
	mutations = np.random.poisson(population * mutation_rates, size=population.shape)	
	loci = npr.randint(0, num_loci, mutations.sum())
	loci_split = np.split(loci, mutations.cumsum())[:-1]
	new_alleles = (target_genome[loci] + 1) % 2 # binomial(1, mutations.sum(), beta)
	new_allele_index = 0
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
				new_genome[locus] = new_allele # xor target_genom[locus]
				new_counts[key] = 1
				new_genomes[key] = new_genome
	if len(new_genomes) > 0:
		for key, new_genome in new_genomes.items():
			index = find_row_nums(nums, genome_to_num(new_genome))
			if index != -1:
				new_genomes.pop(key)
				population[index] += new_counts.pop(key)
	if len(new_genomes) > 0:
		population = np.append(population, new_counts.values())
		genomes = np.vstack((genomes, new_genomes.values()))
	return population, genomes
