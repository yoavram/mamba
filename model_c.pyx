import numpy as np
cimport numpy as np
import numpy.random as npr
cimport cython

DTYPE_INT = np.int
ctypedef np.int_t DTYPE_INT_t
DTYPE_FLOAT = np.float
ctypedef np.float_t DTYPE_FLOAT_t

#cdef extern from "math.h":
#	double pow(double, double)

@cython.boundscheck(False)
@cython.wraparound(False)
def mutation_by_mutation_load(np.ndarray[DTYPE_INT_t, ndim=1] population, np.ndarray[DTYPE_FLOAT_t, ndim=1] mutation_rates):
	cdef np.ndarray[DTYPE_INT_t, ndim=1] mutations
	mutations = npr.poisson(population * mutation_rates)
	cdef Py_ssize_t i
	for i in range(population.shape[0]-1):
		population[i] = population[i] - mutations[i]
		population[i+1] = population[i+1] + mutations[i]   
	return population

@cython.boundscheck(False)
@cython.wraparound(False)
def hamming_fitness_genomes(np.ndarray[DTYPE_INT_t, ndim=2] genomes, np.ndarray[DTYPE_INT_t, ndim=1] target_genome, double s):
	cdef np.ndarray[DTYPE_FLOAT_t, ndim=1] hamming_fitness 
	hamming_fitness = np.zeros(genomes.shape[0], dtype=DTYPE_FLOAT)
	cdef Py_ssize_t i
	for i in range(genomes.shape[0]):
		hamming_fitness[i] = s ** ((target_genome != genomes[i,:]).sum()) 
	return hamming_fitness


@cython.boundscheck(False)
@cython.wraparound(False)
def genomes_to_nums(np.ndarray[DTYPE_INT_t, ndim=2] genomes):
	cdef np.ndarray[DTYPE_FLOAT_t, ndim=1] nums
	cdef np.ndarray[DTYPE_FLOAT_t, ndim=1] i
	cdef DTYPE_FLOAT_t num_loci_f 
	num_loci_f = np.float(genomes.shape[1])
	nums = np.zeros(genomes.shape[0], dtype=DTYPE_FLOAT)
	cdef Py_ssize_t j
	for j in range(genomes.shape[0]):
		i = np.arange(num_loci_f)
		nums[j] = (2. ** i * genomes[j,:]).sum()
	return nums


@cython.boundscheck(False)
@cython.wraparound(False)
def find_row(np.ndarray[int, ndim=2] matrix, np.ndarray[int, ndim=1] target):
    cdef np.ndarray[int, ndim=1] row 
    cdef Py_ssize_t i, j
    cdef bool found
    for i, row in enumerate(matrix):
        found = True
        for j in range(target.shape[0]):
            if target[j] != row[j]:
            	found = False
                break
        if found:
            return i
    return -1
