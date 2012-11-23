import numpy as np
import numpy.random as npr
import random
from math import floor

pop_size = 10 ** 6
num_classes = 10000
num_loci = 1000
s = 0.01
mu = 0.003

# TODO see where range can be chaged to arange and arange to xrange (generator) http://www.jesshamrick.com/2012/04/29/the-demise-of-for-loops/

def create_uniform_mutation_load_population():
	return npr.multinomial(pop_size, [1.0 / num_classes] * num_classes)


def create_mutation_free_population():
	population = np.zeros(num_classes, dtype=np.int32)
	population[0] = pop_size
	return population


def create_fitness_by_mutational_load():
	return np.array([(1 - s) ** x for x in range(num_classes)])


def create_muation_rates():
	return np.array([mu] * num_classes)


def create_target_genome():
	return np.array(np.zeros(num_loci), dtype=np.uint8)


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
	population[:] = population / float(pop_size)
	population[:] = npr.multinomial(pop_size, population)


def selection(population, fitness):
	population[:] = population * fitness
	population[:] = population / population.sum()
	population[:] = npr.multinomial(pop_size, population)


def draw_environmental_changes(ticks, env_change_prob):
	changes = npr.binomial(n=1, p=env_change_prob, size=ticks)
	return changes


def environmental_change(target_genome):
  changed_loci = choose(num_loci, num_loci_to_change)
  target_genome[changed_loci] = (target.genome[changed.loci] + 1) % 2


def choose(n, k):
    return random.sample(xrange(n), k)   


