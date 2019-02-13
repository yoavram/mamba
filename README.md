# Mamba

## Evolutionary simulations in Python

### Overview

This project runs density-based evolutionary simulations used by 
[Yoav Ram](http://www.yoavram.com) and Lilach Hadany at the [Hadany Lab](http://hadanylab.com) at Tel Aviv University.
Yoav is now at IDC Herzliya.

The project is hosted on [GitHub](https://github.com/yoavram/mamba).

In density-based models the population is composed of types or classes, and instead of explicitly accounting for every individual (as it is done in individual-based simulations, such as [proevolutionsimulation]), the model explicitly accounts for the classes and counts how many individuals are in each class.

### The population

The population has several attributes:

#### Genome
This is the types/classes the population is divided to. 
As a starting points the genome is simply the allele(1) sequence of the individual, and can be modeled by a simple vector where the index is the locus (=site on genome, gene) number and the value is the allele identifier. 
Most loci affect the fitness of individuals, but some loci arre *modifiers*, which mean that they affect other attributes rather than fitness, such as the mutation rate.

#### Size
The population size (number of individuals) will be kept constant throughtout the simulation.

#### Counts
An individual count for each class - how many individuals are in each class. 

#### Fitness
Fitness is a relative measure of the reproductive succes of an individual. It is relative to the entire population in the sense that the best organism, the one most optimizes, always has a fitness of unity.
In the most simple model the fitness is calculated as $(1-s)^k$, where $k=d(genome, optimal_genome)$, *d* is the *Hamming distance*, the *optimal_genome* is a reference genome that is the optimal in this specfic environment (for examples, all zeros), and *s* is the selection coefficient, which is the strength of natural selection. For example, with *s=0.01* any additional deleterious mutation reduces the fitness by 1%.

#### Mutation/Recombination Rate
Each class has its own mutation and recombination rate. This rate is determined by a basal population rate ($\mu$ and *r* for mutation and recombination) and the individual's modifiers which determine the rate increase ($\tau$ and $\rho$) and the number of deleterious mutations that induce that increae ($\pi$ and $\phi$).
An example of rates: a basal mutation rate for *E. coli* bacteria is 0.003 mutations per genome per generation, recombination rate 0.00006 recombinations per genome per generation.

### Processes

#### Drift
Drift is the simplest force of evolution.
It randomly chooses individuals for the next generation from the individuals at the current generation. There is no bias and every individual has the same chance of being choosen - it's a random sampling procedure.
Because we keep counts of number of individuals at each class we can simply use these counts with a multinomial random function to do the sampling.

#### Selection
Selection is similar to drift, only the sampling procedure is now biased in favor of classes with higher fitness.

#### Mutation
Mutation changes one genome to another. We need to take an individual from a class and change it to another class.
The mutation rate sets the average number of mutations per genome per generation. The actual number is drawn from a Poisson distribution with the rate as the parameter. The mutations are uniformly distributed across the genome. A mutation changes the current allele to another one without bias - if there are only two alleles (bi-allelic model) than it changes 0 to 1 and 1 to 0, always. If there are three alleles (tri-allelic model) than 0 will change to 1 with probability 1/2 and to 2 with probability 1/2, and so on.

#### Recombination
Recombination changes one genome to another. In bacteria recombination is rare and acts on small fragments of the genome, so we can treat it just like mutation, only that the choice of the new allele is biased on the frequency of each allele in the population, as the alleles doesn't mutate to a new form but rather the allele at that locus (position) is drawn from the population.

#### Environmental changes
We need to allow for the optimal genome to change from time to time, and if need be, recalculate the population fitness (and rates) when that happens.

### Statistics

We need to gather statistics on the population. Every X number of generations record the mean fitness, the frequencies of the different classes and the different classes, the mean mutation rate, etc.

### Flow

We want to start a simulation with a mutation-free population (every one has the optimal genome), let them reach a mutation-selection balance (no significant change in mean fitness from one generation to the next) and the start changing the environment.
The simulation stops when:

  - A certain number of generations has passed (1000? 10000?)
  - When we will have different modifiers - when one wins (this will be implemented when everything else already works)
  
### Implementation

The simulation is implemented in Python (after an attempt at implementing it in R which resulted in a slow simulation). It is highly dependent on NumPy, and all `model.py` functions were thoroughly tested for efficiency using IPython notebook `%timeit` magic against different implementations, including using *cython* and *numba* (albeit a very early version of numba).

The simulation was written on Windows 7 with `Python 2.7.3 |EPD 7.3-2 (64-bit)| (default, Apr 12 2012, 15:20:16) [MSC v.1500 64 bit (AMD64)] on win32` and runs on either an Ubuntu PC with `Python 2.7.3 (default, Aug  1 2012, 05:14:39) [GCC 4.6.3] on linux2` or on a Linux cluster with `Python 2.7.2 (default, Feb 29 2012, 14:04:58) [GCC 4.1.2 20080704 (Red Hat 4.1.2-51)] on linux2`.

Selected modules and packages:
- logging 0.5.1.2
- json 2.0.9
- scipy 0.11.0
- pandas 0.10.1
- numpy 1.6.2
- Cython 0.18

I tried managing the simulation managed with *Sumatra* 0.4.0 but it has some problems running on a cluster.

The results are saved using GZiped CSV files and JSON files.

[Yoav Ram]: http://www.yoavram.com/
[Hadany Evolutionary Theory Lab in Tel-Aviv]: http://sites.google.com/site/hadanylab/
[proevolutionsimulation]: http://proevolutionsimulation.googlecode.com/
[e1071]: http://cran.r-project.org/web/packages/e1071/index.html
[prose]: http://prose.io/
[github]: https://github.com/yoavram/mamba
[python-last-commit]: https://github.com/yoavram/mamba/commit/b9fa9b3b9b30aaa545a7376b54de753cd126dfe5
[alfred]: https://github.com/yoavram/mamba/commit/alfred
[alfred-wallace]: http://en.wikipedia.org/wiki/Alfred_Russel_Wallace

1: An allele is an instance of a gene. For example, at the homoglobin gene, which codes for the Homoglobin protein, which carries oxygen around the body, one could have a "good" allele that does a good job, and one can have a "bad" allele, that doesn't bind oxygen as good as the "good" allele, and therefore the person might suffer from breathing problems.
