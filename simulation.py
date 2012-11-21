from model import *
#import pyximport
#pyximport.install(setup_args={"script_args":["--compiler=mingw32"],
#                              "include_dirs":np.get_include()},
#                  reload_support=True)
import cython_load
from model_c import *
from timeit import timeit

def run1():
	population = create_population()
	fitness = create_fitness()
	mutation_rates = create_muation_rates()
	for i in range(1000):
		population = drift(population)
		population = selection(population, fitness)
		population = mutation(population, mutation_rates)


print timeit(run1, number=1)/1000.
