import numpy as np
cimport numpy as np
import numpy.random as npr
cimport cython
from cpython cimport bool

DTYPE_INT = np.int64
ctypedef np.int64_t DTYPE_INT_t
DTYPE_FLOAT = np.float64
ctypedef np.float64_t DTYPE_FLOAT_t

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
def find_row_nums(list nums, np.ndarray[DTYPE_INT_t, ndim=1] target):
	cdef np.ndarray[DTYPE_INT_t, ndim=1] n
	cdef int i
	for i,n in enumerate(nums):
		if arr_equal(n, target):
			return i
	return -1

@cython.boundscheck(False)
@cython.wraparound(False)
def arr_equal(np.ndarray[DTYPE_INT_t, ndim=1] a1, np.ndarray[DTYPE_INT_t, ndim=1] a2):
	try:
		a1, a2 = np.asarray(a1), np.asarray(a2)
	except:
		return False
	if a1.shape != a2.shape:
		return False
	cdef Py_ssize_t i
	for i in np.arange(a1.shape[0]):
		if a1[i] != a2[i]:
			return False
	return True
