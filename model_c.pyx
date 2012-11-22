import numpy as np
cimport numpy as np
import numpy.random as npr
cimport cython

# USE ctypedef np.float64_t dtype_t ?

@cython.boundscheck(False)
@cython.wraparound(False)
def mutation_by_mutation_load(np.ndarray[long, ndim=1] population, np.ndarray[double, ndim=1] mutation_rates):
    cdef np.ndarray[long, ndim=1, negative_indices=False] mutations
    mutations = npr.poisson(population*mutation_rates)
    cdef Py_ssize_t i
    for i in range(population.shape[0]-1):
        population[i] -= mutations[i]
        population[i+1] += mutations[i]   
    return population

@cython.boundscheck(False)
@cython.wraparound(False)
def hamming_fitness_genomes(np.ndarray[int, ndim=2] genomes, np.ndarray[int, ndim=1] target_genome, double s):
	'''this is slightly faster than iterating without cython and twice as fast as using np.apply_along_axis'''
    cdef np.ndarray[double, ndim=1] hamming_fitness 
    hamming_fitness = np.zeros(genomes.shape[0], dtype=np.int)
    cdef Py_ssize_t i
    for i in range(genomes.shape[0]):
    	# TODO clib power?
        hamming_fitness[i] = s**((target_genome!=genomes[i,:]).sum()) 
    return hamming_fitness
