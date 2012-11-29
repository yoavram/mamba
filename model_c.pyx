import numpy as np
cimport numpy as np
import numpy.random as npr
cimport cython
from cpython cimport bool

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
@cython.wraparound(False) # TODO int -> DTYPE_...
def find_row(np.ndarray[DTYPE_INT_t, ndim=2] matrix, np.ndarray[DTYPE_INT_t, ndim=1] target):
	cdef np.ndarray[DTYPE_INT_t, ndim=1] row 
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


@cython.boundscheck(False)
@cython.wraparound(False)
def find_row_nums(np.ndarray[DTYPE_FLOAT_t, ndim=1] nums, DTYPE_FLOAT_t target):
    cdef Py_ssize_t i
    cdef DTYPE_FLOAT_t n
    for i,n in enumerate(nums):
        if n == target:
            return i
    return -1
