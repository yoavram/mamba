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
@cython.wraparound(False) # TODO int -> DTYPE_...
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

@cython.boundscheck(False)
@cython.wraparound(False) # TODO int -> DTYPE_...
cdef cfind_row(np.ndarray[DTYPE_INT_t, ndim=2] matrix, np.ndarray[DTYPE_INT_t, ndim=1] target):
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


def mutation_explicit_genomes(population, genomes, mutation_rates, num_loci, target_genome):
	'''limit to one mutation per individual, doesn't update rates or fitness'''
	mutations = np.random.poisson(population * mutation_rates, size=population.shape)	
	loci = npr.randint(0, num_loci, mutations.sum())
	loci_split = np.split(loci, mutations.cumsum())[:-1]
	new_alleles = (target_genome[loci] + 1) % 2
	new_allele_index = 0
	# create dict of new strains
	new_counts = {}
	new_genomes = {}
	for strain in range(len(loci_split)):
		population[strain] = population[strain] - mutations[strain]
		assert population[strain] >= 0  # ASSERT
		for locus in loci_split[strain]:
			new_allele = new_alleles[new_allele_index]
			new_allele_index += 1
			key = (strain, locus, new_allele)
			if key in new_counts:
				new_counts[key] += 1
			else:
				new_genome = genomes[strain,:].copy()				
				new_genome[locus] = new_allele
				index = find_row(genomes, new_genome)
				if index == -1:
					new_counts[key] = 1
					new_genomes[key] = new_genome
				else:
					population[index] += 1
	# update 
	if len(new_counts) > 0:
		population = np.append(population, new_counts.values())
		genomes = np.vstack((genomes, new_genomes.values()))
	return population, genomes


def mutation_explicit_genomes_cdef(np.ndarray[DTYPE_INT_t, ndim=1] population, np.ndarray[DTYPE_INT_t, ndim=2] genomes, np.ndarray[DTYPE_FLOAT_t, ndim=1] mutation_rates, DTYPE_INT_t num_loci, np.ndarray[DTYPE_INT_t, ndim=1] target_genome):
	'''limit to one mutation per individual, doesn't update rates or fitness'''
	cdef np.ndarray[DTYPE_INT_t, ndim=1] mutations
	cdef np.ndarray[DTYPE_INT_t, ndim=1] loci
	cdef list loci_split
	cdef np.ndarray[DTYPE_INT_t, ndim=1] new_alleles
	cdef Py_ssize_t new_allele_index, strain, locus
	cdef DTYPE_INT_t new_allele
	cdef Py_ssize_t index
	cdef dict new_counts
	cdef dict new_genomes
	cdef tuple key
	cdef np.ndarray[DTYPE_INT_t, ndim=1] new_genome

	mutations = np.random.poisson(population * mutation_rates, size=population.shape[0])	
	loci = npr.randint(0, num_loci, mutations.sum())
	loci_split = np.split(loci, mutations.cumsum())[:-1]
	new_alleles = (target_genome[loci] + 1) % 2
	new_allele_index = 0
	# create dict of new strains
	new_counts = {}
	new_genomes = {}
	for strain in range(len(loci_split)):
		population[strain] = population[strain] - mutations[strain]
		assert population[strain] >= 0  # ASSERT
		for locus in loci_split[strain]:
			new_allele = new_alleles[new_allele_index]
			new_allele_index += 1
			key = (strain, locus, new_allele)
			if key in new_counts:
				new_counts[key] += 1
			else:
				new_genome = genomes[strain,:].copy()				
				new_genome[locus] = new_allele
				index = cfind_row(genomes, new_genome)
				if index == -1:
					new_counts[key] = 1
					new_genomes[key] = new_genome
				else:
					population[index] += 1
	# update 
	if len(new_counts) > 0:
		population = np.append(population, new_counts.values())
		genomes = np.vstack((genomes, new_genomes.values()))
	return population, genomes

