# import numpy as np
# import pyximport
# pyximport.install(setup_args={"script_args":["--compiler=mingw32"],
#                               "include_dirs":np.get_include()},
#                   reload_support=True)
import cython_load
from time import clock

from model import drift, selection, create_muation_rates
from model import create_fitness_by_mutational_load as create_fitness
from model import create_mutation_free_population as create_population
from model_c import mutation_by_mutation_load as mutation


def run(ticks=1000, tick_interval=100):
	tic = clock()
	population = create_population()
	fitness = create_fitness()
	mutation_rates = create_muation_rates()

	print "Starting simulation with ", ticks, "ticks"
	for tick in range(ticks + 1):
		drift(population)
		selection(population, fitness)
		mutation(population, mutation_rates)

		if tick_interval != 0 and tick % tick_interval == 0:
			print "Tick", tick
	toc = clock()
	print "Simulation finished,", tick, "ticks, time elapsed", (toc-tic), "seconds"
	return population

if __name__=="__main__":
	p = run()

