import numpy as np
from numpy import append
from numpy.random import random_integers, multinomial, poisson
import scipy as sp
from ConfigParser import ConfigParser
import time

DEBUG = True

MUTATION_FREE = "mutation-free"

GENE = np.uint16

def add_row(m, arr):
    arr = arr.reshape( (1,1000) ) 
    return np.append(m, arr, 0)

def add_col(m, arr):
    return np.append(m, arr, 1)

def get_col(m, col):
    return m[:,col]

def get_row(m, row):
    return m[row]

def create_new_allele_method(num_of_alleles):
    if num_of_alleles == 2:
        def new_allele(current_allele):
            return (current_allele + 1) % 2        
    else:
        def new_allele(current_allele):
            i = random_integers(1, num_of_alleles-1)
            return (current_allele + i) % num_of_alleles
    return new_allele

class Population:
    def __init__(self, context):
        if context.founder == MUTATION_FREE:
            context.optimal_genome = np.array( [0]*context.num_of_genes, dtype=GENE)
            self.size = context.population_size
            self.fsize = float(self.size)
            self.genomes = np.zeros( (1, context.num_of_genes), dtype=GENE) # key=row to genome, locus=col to alleles in population
            self.counts = np.array( [self.size], dtype=np.uint64 ) # key=index to count
            self.mutation_rates = np.array([context.mutation_rate(self.genomes[0])], dtype=np.float64) # key=index to mutation rate
            self.recombination_rates = np.array([context.recombination_rate(self.genomes[0])], dtype=np.float64) # key=index to recombination rate
            self.fitness = np.array( [context.fitness(self.genomes[0])], dtype=np.float64) # key=index to fitness
            self.revmap = { self.genomes[0].tostring() : 0 }
        else:
            raise ValueError("Unknown founder '%s%" % context.founder)


    def frequencies(self):
        return self.counts/self.fsize
    
    def mean_fitness(self):
        return self.counts.dot(self.fitness.T)

class Context:
    def __init__(self):
        self.basic_mutation_rate = 0.003
        self.basic_recombination_rate = 0.00006
        self.selection_coefficient = 0.1
        self.population_size = 100000.0 # must be float
        self.num_of_genes = 1000
        self.founder = "mutation-free"
        self.mean_fitness = 1
        self.tick = 1
        self.num_of_alleles = 2
        self.new_allele_by_mutation = create_new_allele_method(self.num_of_alleles)

    def fitness(context, genome):
        return sum(context.optimal_genome==genome)

    def mutation_rate(context, genome):
        return context.basic_mutation_rate

    def recombination_rate(context, genome):
        return context.basic_recombination_rate

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
                    new_genome[locus] = context.new_allele_by_mutation(new_genome[locus])
                new_key = population.revmap.get(new_genome.tostring(), -1)
                if new_key == -1:
                    context.add_new_class(population, new_genome)
                else:
                    population.counts[new_key] += 1
                # check if class is now empty, if it is replace it with the last class
                if population.counts[key] == 0:# TODO test this
                    remove_empty_class(context, population, key)
        return population

    def add_new_class(context, population, new_genome):
        new_key = len(population.counts)
        population.counts = append(population.counts, 1)
        population.fitness = append(population.fitness, context.fitness(new_genome))
        population.mutation_rates = append(population.mutation_rates, context.mutation_rate( new_genome))
        population.recombination_rates = append(population.recombination_rates, context.recombination_rate( new_genome))
        population.revmap[new_genome.tostring()] = new_key 
        population.genomes = add_row(population.genomes, new_genome)
        
    
    def remove_empty_class(context, population, key):
        last_key = len(population.counts)-1
        population.revmap.pop(population.genomes[key].tostring())
        if key != last_key:
            # move last key to key
            population.count[key] = population.counts[last_key]
            population.fitness[key] = population.fitness[last_key]
            population.mutation_rates[key] = population.mutation_rates[last_key]
            population.recombination_rates[key] = population.recombination_rates[last_key]
            population.genomes[key] = population.genomes[last_key]
            populaiton.revmap[population.genomes[last_key].tostring()] = key
        # remove last key
        population.counts = population.counts[:last_key]
        population.fitness = population.fitness[:last_key]
        population.mutation_rates = population.mutation_rates[:last_key]
        population.recombination_rates = population.recombination_rates[:last_key]
        population.genomes = population.genomes[:last_key]            

    def remove_empty_classes(context, population):
        keys = [i for i in range(len(population.counts)-1,-1,-1) if population.counts[i]==0]
        for key in keys:
           context.remove_empty_class(population, key)


    def new_allele_by_recombination(context, population, locus):
        draw = multinomial(1, population.frequencies())
        assert sum(draw)==1, "multinomial wasn't 1"
        clazz = draw.argmax()
        allele = population.genomes[clazz, locus]
        return allele
                
    def recombination(context, population):
        rates = population.recombination_rates * population.counts
        class_recombinations = poisson([rates]) 
        for key in range(len(class_recombinations)):
            class_count = population.counts[key]
            individual_recombinations = multinomial(class_recombinations[key], [1./class_count]*class_count)
            loci_list = [ random_integers(0, context.num_of_genes-1, x) for x in individual_recombinations if x>0 ]
            for loci in loci_list:
                new_genome = population.genomes[key].copy()
                population.counts[key] -= 1
                assert population.counts[key] >= 0, "count at key %d is negative %d" % (key, population.counts[key])
                for locus in loci:
                    new_genome[locus] = context.new_allele_by_recombination(population, locus)
                new_key = population.revmap.get(new_genome.tostring(), -1)
                if new_key == -1:
                    context.add_new_class(population, new_genome)
                else:
                    population.counts[new_key] += 1
                # check if class is now empty, if it is replace it with the last class
                if population.counts[key] == 0:
                    remove_empty_class(context, population, key)
        return population

    def test_termination(context, population):
        return context.step == 10
        mean_fitness = population.mean_fitness() 
        dif = np.abs(mean_fitness - context.mean_fitness)
        context.mean_fitness = mean_fitness
        if dif < 10^-3:
            print "Terminated on tick %d with mean fitness %f and difference in mean fitness %f" % (context.tick, mean_fitness.mean_fitness, dif)
            return True
        return False

    def run(self):
        tick = time.clock()
        print "Starting simulation at time %f" % tick
        population = Population(self)

        while not self.test_termination( population):
            if self.step % 100 == 0:
                print "Step %d" % self.step
            population = self.drift( population)
            population = self.selection( population)
            population = self.mutation( population)
            population = self.recombination( population)
            self.step += 1
        print "Saving population to file"
        fout = open("population", "wb")
        pickle.dump(population, fout)
        fout.close()
        tock = time.clock()
        print "Finished simulation at time %f, elapsed time %f" % (tock, (tock-tick))

if __name__ == "__main__":
    c = Context()
    c.run()
    
