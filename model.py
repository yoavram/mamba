import numpy as np
import numpy.random as npr
import random
from math import floor

# TODO see where range can be chaged to arange and arange to xrange (generator) http://www.jesshamrick.com/2012/04/29/the-demise-of-for-loops/

def create_uniform_mutation_load_population(num_classes):
	return npr.multinomial(pop_size, [1.0 / num_classes] * num_classes)


def create_mutation_free_population(pop_size, num_classes):
	population = np.zeros(num_classes, dtype=np.int)
	population[0] = pop_size
	return population


def create_fitness_by_mutational_load(s, num_classes):
	return np.array([(1 - s) ** x for x in range(num_classes)])


def create_muation_rates(mu, num_classes):
	return np.array([mu] * num_classes)


def create_target_genome(num_loci):
	return np.array(np.zeros(num_loci), dtype=np.int)


def hamming_fitness_genome(genome, target_genome, s):
	return s ** (genome != target_genome).sum()


def hamming_fitness_genomes(genomes, target_genome, s):
	'''The cython version is faster'''
	return np.apply_along_axis(hamming_fitness_genome, 1, genomes, target_genome, s)


def genome_to_num(genome):
	i = np.arange(genome.shape[0])
	return (2. ** i * genome).sum()


def drift(population):
	pop_size = population.sum()
	p = population / float(pop_size)
	population[:] = npr.multinomial(pop_size, p)


def selection(population, fitness):
	pop_size = population.sum()
	p = population * fitness
	p[:] = p / p.sum()
	population[:] = npr.multinomial(pop_size, p)

def draw_environmental_changes(ticks, env_change_prob):
	changes = npr.binomial(n=1, p=env_change_prob, size=ticks)
	return changes


def environmental_change(target_genome):
  changed_loci = choose(num_loci, num_loci_to_change)
  target_genome[changed_loci] = (target.genome[changed.loci] + 1) % 2


def choose(n, k):
    return random.sample(xrange(n), k)   

