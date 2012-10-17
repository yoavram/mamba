import numpy as np
import scipy as sp
from ConfigParser import ConfigParser

MUTATION_FREE = "mutation-free"

class Context:
    pass

class Population:
    pass

def create_context():
    c = Context()
    c.mutation_rate = 0.003
    c.recombination_rate = 0.00006
    c.selection_coefficient = 0.1
    c.population_size = 100000
    c.num_of_genes = 1000
    c.founder = "mutation-free"
    return c

def create_population(context):
    if context.founder == MUTATION_FREE:
        p = Population()
        mutation_free_genome = np.array([0] * context.num_of_genes)
        p.genomes = np.array( [ mutation_free_genome ] )
        p.counts = np.array( [context.population_size] )
        p.mutation_rates = np.array([context.mutation_rate])
        return p
    else:
        raise ValueError("Unknown founder '%s%" % c.founder)

def drift(context, population):
    frequencies =  population.counts/context.population_size
    next_population.counts = np.random.multinomial(context.population_size,)
    return next_population

def selection(context, population):
    pass

def mutation(context, population):
    for key in range(len(population.genomes.keys())):
        mutations = np.random.poisson(population.mutation_rates[key], population.count[key])
        for individual in range(len(mutations)):
            loci = np.random.random_integers(0, context.num_of_genes, mutations[individual]) # TOOD: without return?
            genome = p.genomes[key]
            for locus in loci:
                cur_allele = genome[locus]
                genome[locus] = (cur_allele + 1) % 2
            for k,v in population.genomes.items():
                if v == genome:
                
            
def recombination(context, population):
    pass

def test_termination(context, population):
    pass

def run():
    context = create_context()
    population = create_population(context)
    
