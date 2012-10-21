import numpy as np
from numpy.random import random_integers, multinomial, poisson
import scipy as sp
from ConfigParser import ConfigParser
import time

DEBUG = True

MUTATION_FREE = "mutation-free"

GENE = np.uint16

class Context:
    pass

class Population:
    def __init__(self):
        pass

    def frequencies(self):
        return self.counts/self.fsize
    
    def mean_fitness(self):
        return self.counts.dot(self.fitness.T)

def add_row(m, arr):
    arr = arr.reshape( (1,1000) ) # TODO
    return np.append(m, arr, 0)

def add_col(m, arr):
    return np.append(m, arr, 1)

def get_col(m, col):
    return m[:,col]

def get_row(m, row):
    return m[row]

def create_context():
    c = Context()
    c.mutation_rate = 0.003
    c.recombination_rate = 0.00006
    c.selection_coefficient = 0.1
    c.population_size = 100000.0 # must be float
    c.num_of_genes = 1000
    c.founder = "mutation-free"
    c.mean_fitness = 1
    c.tick = 1
    c.num_of_alleles = 2
    c.new_allele = create_new_allele_method(c.num_of_alleles)
    return c

def create_new_allele_method(num_of_alleles):
    if num_of_alleles == 2:
        def new_allele(current_allele):
            return (current_allele + 1) % 2        
    else:
        def new_allele(current_allele):
            i = random_integers(1, num_of_alleles-1)
            return (current_allele + i) % num_of_alleles
    return new_allele

def fitness(context, genome):
    return sum(context.optimal_genome==genome)

def mutation_rate(context, genome):
    return context.mutation_rate

def recombination_rate(context, genome):
    return context.recombination_rate

def create_population(context):
    if context.founder == MUTATION_FREE:
        context.optimal_genome = np.array( [0]*context.num_of_genes, dtype=GENE)
        p = Population()
        p.size = context.population_size
        p.fsize = float(p.size)
        p.genomes = np.zeros( (1, context.num_of_genes), dtype=GENE) # key=row to genome, locus=col to alleles in population
        p.counts = np.array( [p.size], dtype=np.uint64 ) # key=index to count
        p.mutation_rates = np.array([context.mutation_rate], dtype=np.float64) # key=index to mutation rate
        p.recombination_rates = np.array([context.recombination_rate], dtype=np.float64) # key=index to recombination rate
        p.fitness = np.array( [fitness(context, p.genomes[0])], dtype=np.float64) # key=index to fitness
        p.revmap = { p.genomes[0].tostring() : 0 }
        
        return p
    else:
        raise ValueError("Unknown founder '%s%" % context.founder)


def drift(context, population):
    freqs = population.frequencies()
    population.counts = multinomial(context.population_size, freqs)
    return population

def selection(context, population):
    freqs = population.counts*population.fitness
    freqs = freqs/freqs.sum()
    population.counts = multinomial(context.population_size, freqs)
    return population
    
def mutation(context, population):
    # first draw number of mutations for each class
    # this is important because each class can have a different mutation rate
    rates = population.mutation_rates * population.counts
    class_mutations = poisson([rates]) #???
    for key in range(len(class_mutations)):
        # draw how the mutations are ditributed in the class
        class_count = population.counts[key]
        individual_mutations = multinomial(class_mutations[key], [1./class_count]*class_count)
        loci_list = [ random_integers(0, context.num_of_genes-1, x) for x in individual_mutations if x>0 ]
        for loci in loci_list:
            new_genome = population.genomes[key].copy()
            population.counts[key] -= 1
            assert population.counts[key] >= 0, "count at key %d is negative %d" % (key, population.counts[key])
            for locus in loci:
                new_genome[locus] = context.new_allele(new_genome[locus])
            new_key = population.revmap.get(new_genome.tostring(), -1)
            if new_key == -1:
                new_key = len(population.counts)
                population.counts = np.append(population.counts, 1)
                population.fitness = np.append(population.fitness, fitness(context, new_genome))
                population.mutation_rates = np.append(population.mutation_rates, mutation_rate(context, new_genome))
                population.recombination_rates = np.append(population.recombination_rates, recombination_rate(context, new_genome))
                population.revmap[new_genome.tostring()] = new_key # TODO check this
                population.genomes = add_row(population.genomes, new_genome)
                assert (population.genomes[new_key] == new_genome).all()
            else:
                population.counts[new_key] += 1
            # check if class is now empty, if it is replace it with the last class
            if population.counts[key] == 0:# TODO test this
                remove_empty_class(context, population, key)
            
    return population

def remove_empty_class(context, population, key):
    last_key = len(population.counts)-1
    population.count[key] = population.pop()
    population.fitness[key] = population.fitness.pop()
    population.mutation_rates[key] = population.mutation_rates.pop()
    population.recombination_rates[key] = population.recombination_rates.pop()
    new_genome = population.genomes[-1]
    population.genomes[key] = new_genome
    population.genomes = population.genomes[:-1]
    populaiton.revmap[new_genome.tostring()] = key
            
def recombination(context, population):
    return population

def test_termination(context, population):
    return context.tick == 10
    mean_fitness = population.mean_fitness() 
    dif = np.abs(mean_fitness - context.mean_fitness)
    context.mean_fitness = mean_fitness
    if dif < 10^-3:
        print "Terminated on tick %d with mean fitness %f and difference in mean fitness %f" % (context.tick, mean_fitness.mean_fitness, dif)
        return True
    return False

def run():
    tick = time.clock()
    print "Starting simulation at time %f" % tick
    context = create_context()
    population = create_population(context)

    while not test_termination(context, population):
        if context.tick % 100 == 0:
            print "Tick %d" % context.tick
        population = drift(context, population)
        population = selection(context, population)
        population = mutation(context, population)
        population = recombination(context, population)
        context.tick += 1
    print "Saving population to file"
    fout = open("population", "wb")
    pickle.dump(population, fout)
    fout.close()
    tock = time.clock()
    print "Finished simulation at time %f, elapsed time %f" % (tock, (tock-tick))

if __name__ == "__main__":
    run()
    
