import numpy as np
cimport numpy as np
import numpy.random as npr
cimport cython

@cython.boundscheck(False)
def mutation(np.ndarray[np.int32_t, ndim=1, negative_indices=False] population, np.ndarray[double, ndim=1, negative_indices=False] mutation_rates):
    cdef np.ndarray[np.int32_t, ndim=1, negative_indices=False] mutations
    mutations = npr.poisson(population*mutation_rates)
    cdef Py_ssize_t i
    for i in range(population.shape[0]-1):
        population[i] -= mutations[i]
        population[i+1] += mutations[i]   
    return population