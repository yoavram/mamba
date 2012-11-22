import numpy as np
cimport numpy as np
import numpy.random as npr
cimport cython

@cython.boundscheck(False)
def mutation_by_mutation_load(np.ndarray[long, ndim=1, negative_indices=False] population, np.ndarray[double, ndim=1, negative_indices=False] mutation_rates):
    cdef np.ndarray[long, ndim=1, negative_indices=False] mutations
    mutations = npr.poisson(population*mutation_rates)
    cdef Py_ssize_t i
    for i in range(population.shape[0]-1):
        population[i] -= mutations[i]
        population[i+1] += mutations[i]   
    return population

@cython.boundscheck(False)
def hamming_fitness_genomes(np.ndarray[int, ndim=2, negative_indices=False] genomes, np.ndarray[int, ndim=1, negative_indices=False] target_genome):
	'''this is slightly faster than iterating without cython and twice as fast as using np.apply_along_axis'''
    cdef np.ndarray[int, ndim=1, negative_indices=False] hamming_fitness 
    hamming_fitness = np.zeros(genomes.shape[0], dtype=np.int)
    cdef Py_ssize_t i
    for i in range(genomes.shape[0]):
        hamming_fitness[i] = (target_genome!=genomes[i,:]).sum()
    return hamming_fitness
