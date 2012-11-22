import numpy as np
import numpy.random as npr


pop_size = 10**6
num_classes = 10000
num_loci = 1000
s = 0.01
mu = 0.003

def create_uniform_mutation_load_population():
	return npr.multinomial(pop_size, [1.0/num_classes]*num_classes)

def create_mutation_free_population():
	population = np.zeros(num_classes, dtype=np.int32)
	population[0] = pop_size
	genomes = np.zeros( (num_classes, num_loci), dtype=np.int)
	return population

def create_fitness_by_mutational_load():
    return np.array( [ (1-s)**x for x in range(num_classes) ] )

def create_muation_rates():
	return np.array( [mu]*num_classes )

def create_target_genome():
	return np.array(zeros(num_loci), dtype=np.uint8)

def hamming_fitness_genome(genome, target_genome, s):
	return s**(genome != target_genome).sum()


def hamming_fitness_genomes(genomes, target_genome, s):
	'''The cython version is faster'''
    return np.apply_along_axis(hamming_fitness_genome, 1, genomes, target_genome, s) 

def genome_to_int(genome):
	i = np.arange(genome.shape[0])
	return int((2.**i*genome).sum())

def drift(population):
	pop_size = population.sum()
	population[:] = population/float(pop_size)
	population[:] = npr.multinomial(pop_size, population)

def selection(population, fitness):
	population[:] = population*fitness
	population[:] = population/population.sum()
	population[:] = npr.multinomial(pop_size, population)

def draw.environmental.changes(ticks, env_change_prob) {
  changes = npr.binomial(n=1, p=env_change_prob, size=ticks)
  return changes
}
