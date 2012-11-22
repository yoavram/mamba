# import numpy as np
# import pyximport
# pyximport.install(setup_args={"script_args":["--compiler=mingw32"],
#                               "include_dirs":np.get_include()},
#                   reload_support=True)
import cython_load
from time import clock

from model import drift, selection, create_fitness, create_muation_rates
from model import create_mutation_free_population as create_population
from model_c import mutation_by_mutation_load as mutation

def run(ticks=10, tick_interval=1):
	tic = clock()
	population = create_population()
	fitness = create_fitness()
	mutation_rates = create_muation_rates()
	
	for tick in range(ticks):
		drift(population)
		selection(population, fitness)
		mutation(population, mutation_rates)

		if tick % tick_interval == 0:
			print "Tick", tick
	toc = clock()
	print "Simulation finished, time elapsed", (toc-tic), "seconds"
	return population

if __name__=="__main__":
	print run()[0]
