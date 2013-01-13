import numpy as np
import random
from math import floor
from scipy.spatial.distance import cdist, hamming

# TODO see where range can be chaged to arange and arange to xrange (generator) http://www.jesshamrick.com/2012/04/29/the-demise-of-for-loops/

import log
logger = log.get_logger('model')


def create_uniform_mutation_load_population(pop_size, num_classes):
	return np.random.multinomial(pop_size, [1.0 / num_classes] * num_classes)


def create_mutation_free_population(pop_size, num_classes):
	population = np.zeros(num_classes, dtype=np.int)
	population[0] = pop_size
	return population


def create_fitness_by_mutational_load(s, num_classes):
	return  np.array([(1 - s) ** load for load in range(num_classes)])


def create_rates(basic_rate, num_classes):
	return np.array([basic_rate] * num_classes)


def create_muation_rates(mu, num_classes):
	return create_rates(mu, num_classes)


def create_recombination_rates(r, num_classes):
	return create_rates(r, num_classes)


def create_rates_with_modifiers(basic_rate, genomes, fitness, s, num_loci, th_offset, incr_offset, create_rates):
	threshold = (1 - s) ** genomes[:, num_loci + th_offset]
	increase = genomes[:, num_loci + incr_offset]
	rates = create_rates(basic_rate, genomes.shape[0])
	hypers = fitness <= threshold
	rates[hypers] *= increase[hypers]
	return rates


def create_mutation_rates_with_modifiers(mu, genomes, fitness, s, num_loci):
	return create_rates_with_modifiers(mu, genomes, fitness, s, num_loci, 0, 1, create_muation_rates)


def create_recombination_rates_with_modifiers(r, genomes, fitness, s, num_loci):
	return create_rates_with_modifiers(r, genomes, fitness, s, num_loci, 2, 3, create_recombination_rates)


def create_target_genome(num_loci):
	return np.array(np.zeros(num_loci), dtype=np.int)


def hamming_fitness_genome(genome, target_genome, s):
	load = hamming(genome[:num_loci], target_genome) * target_genome.shape[0]
	return (1 - s) ** load


def hamming_fitness_genomes(genomes, target_genome, s, num_loci):
	num_loci = target_genome.shape[0]
	load = cdist(genomes[:, :num_loci], target_genome.reshape(1, num_loci), 'hamming') * num_loci
	return ((1 - s) ** load).reshape(genomes.shape[0])


def genome_to_num(genome, num_loci):
    non_zero = genome.nonzero()[0]
    non_zero = non_zero[non_zero < num_loci]
    return (2. ** non_zero).sum() # this is faster than numexpr


def genomes_to_nums(genomes, num_loci):
    return np.array([genome_to_num(g, num_loci) for g in genomes])


def find_row_nums(nums, target):
	# cython version is slightly faster
	for i,n in enumerate(nums):
		if n == target:
			return i
	return -1


def drift(population):
	pop_size = population.sum()
	p = population / float(pop_size)
	population[:] = np.random.multinomial(pop_size, p)
	return population


def selection(population, fitness):
	pop_size = population.sum()
	p = population * fitness.reshape(population.shape)
	p[:] = p / p.sum()
	population[:] = np.random.multinomial(pop_size, p)
	return population


def draw_environmental_changes(ticks, env_change_prob):
	changes = np.random.binomial(n=1, p=env_change_prob, size=ticks)
	return changes


def environmental_change(target_genome):
	changed_loci = choose(num_loci, num_loci_to_change)
	target_genome[changed_loci] = (target.genome[changed.loci] + 1) % 2


def choose(n, k):
 	return random.sample(xrange(n), k)


def invasion(population, genomes, modifiers, rate, num_loci):
	pop2 = population.copy()
	pop2 *= rate
	population -= pop2
	gen2 = genomes.copy()
	gen2[:, num_loci:] = np.array(modifiers)
	population = np.concatenate((population, pop2),axis=0)
	genomes = np.concatenate((genomes, gen2),axis=0)
	return population, genomes


def mutation_explicit_genomes(population, genomes, mutation_rates, num_loci, target_genome, nums):
	mutations = np.random.poisson(population * mutation_rates, size=population.shape)	
	loci = np.random.randint(0, num_loci, mutations.sum())
	loci_split = np.split(loci, mutations.cumsum())[:-1]
	new_alleles = (target_genome[loci] + 1) % 2 # binomial(1, mutations.sum(), beta)
	new_allele_index = 0
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
				new_genome[locus] = new_allele # xor target_genom[locus]
				new_counts[key] = 1
				new_genomes[key] = new_genome
	if len(new_genomes) > 0:
		for key, new_genome in new_genomes.items():
			index = find_row_nums(nums, genome_to_num(new_genome))
			if index != -1:
				new_genomes.pop(key)
				population[index] += new_counts.pop(key)
	if len(new_genomes) > 0:
		population = np.append(population, new_counts.values())
		genomes = np.vstack((genomes, new_genomes.values()))
	return population, genomes


def mutation_recombination(population, genomes, mutation_rates, recombination_rates, num_loci, target_genome, nums):
	total_rates = mutation_rates + recombination_rates
	prob_mu = mutation_rates/total_rates
	popultation_rates = population * total_rates
	events = np.random.poisson(popultation_rates, size=population.shape)
	total_events = events.sum()	
	events  = np.array((events, population)).min(axis=0) # no more than one mutation per individual
	# DEBUG STUFF
	if total_events > events.sum():
		logger.debug("Reduced %.4f of events from %d to %d" % ((1-events.sum()/float(total_events)), total_events, events.sum()))
	# DEBUG END
	mutations = np.round(events * prob_mu)
	mutations = np.array([np.int(x) for x in mutations])
	recombinations = events - mutations
	events_cumsum = events.cumsum()
	total_events = events_cumsum[-1]
	loci = np.random.randint(0, num_loci, total_events)
	loci_split = np.split(loci, events.cumsum())[:-1] # split by strain
	loci_split = [np.split(x, mutations[i:i+1]) for i,x in enumerate(loci_split)] # split by mutation/recombination
	new_counts = {}
	new_genomes = {}

	# 0 - mutation, 1 - recombination
	for strain in range(population.shape[0]):
		population[strain] = population[strain] - events[strain]
		assert population[strain] >= 0  # ASSERT

		for method in range(len(loci_split[strain])):
			_loci = loci_split[strain][method]	
			if len(_loci) == 0:
				continue
			if method == 0: # mutation
				new_alleles = (target_genome[_loci] + 1) % 2 # binomial(1, mutations.sum(), beta)
			elif method == 1: # recombination
				donors = np.random.multinomial(len(_loci), population/float(population.sum()))
				donors = np.repeat(np.arange(donors.shape[0]), donors)
				new_alleles = genomes[donors, _loci]

			for i, locus in enumerate(_loci):
				new_allele = new_alleles[i]
				key = (strain, locus, new_allele)
				if key in new_counts:
					new_counts[key] += 1
				else:
					new_genome = genomes[strain, :].copy()				
					new_genome[locus] = new_allele # xor target_genom[locus]
					new_counts[key] = 1
					new_genomes[key] = new_genome

	if len(new_genomes) > 0:
		for key, new_genome in new_genomes.items():
			index = find_row_nums(nums, genome_to_num(new_genome, num_loci))
			if index != -1:
				new_genomes.pop(key)
				population[index] += new_counts.pop(key)

	if len(new_genomes) > 0:
		population = np.append(population, new_counts.values())
		genomes = np.vstack((genomes, new_genomes.values()))

	return population, genomes
