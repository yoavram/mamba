import numpy as np
import numpy.random as npr


pop_size = 10**6
num_classes = 10**3
s = 0.01
mu = 0.003

def create_population():
	return npr.multinomial(pop_size, [1.0/num_classes]*num_classes)


def create_fitness():
    return np.array( [ (1-s)**x for x in range(num_classes) ] )

def create_muation_rates():
	return np.array( [mu]*num_classes )

def drift(population):
	pop_size = np.float32(population.sum())
	p = population/pop_size
	population[:] = npr.multinomial(pop_size, p)
	return population


def selection(population, fitness):
	pop_size = np.float32(population.sum())
	p = population*fitness/pop_size
	population[:] = npr.multinomial(pop_size, p)
	return population
