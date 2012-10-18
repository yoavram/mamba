# Mamba

## Evolutionary simulations in Python and R

### Overview

This project runs density-based evolutionary simulations used by 
[Yoav Ram] at the [Hadany Evolutionary Theory Lab in Tel-Aviv].

In density-based models the population is composed of types or classes, and instead of explicitly accounting for every individual (as it is done in individual-based simulations, such as [proevolutionsimulation]), the model explicitly accounts for the classes and counts how many individuals are in each class.

### The population

The population has several attributes:

#### Genotype/Genome
This is the types/classes the population is divided to. 
As a starting points the genotype is simply a the allele(1) sequence of the individual, and can be modeled by a simple vector where the index is the locus (=site on genome, gene) number and the value is the allele identifier.

#### Size
The population size (number of individuals) will be kept constant throughtout the simulation.

#### Counts
A simple counter for each class - how many individuals are in this class.

#### Fitness
Fitness is a relative measure of the reproductive succes of an individual. It is relative to the entire population in the sense that the best organism, the one most optimizes, always has a fitness of unity.
In the most simple model the fitness is calculated as (1-s)^k, where k=d(genome, optimal_genome), d is the Hamming distance, the optimal_genome is a reference genome that is the optimal in this specfic environment (for examples, all zeros), and s is the selection coefficient, which is the amplitude of natural selection (for example, s=0.01).

#### Mutation/Recombination Rate
Each class has it's own mutation and recombination rate. As a starting point they all have the same rate but at some point we would like to be able to set their rates according to their genomes.
An example of rates are: mutation rate 0.003 mutations per genome per generation, recombination rate 0.0001 recombinations per genome per generation.

### Processes

#### Drift
Drift is the simplest force of evolution.
It randomly chooses individuals for the next generation from the individuals at the current generation. There is no bias and every individual has the same chance of being choosen - it's a random sampling procedure.
Because we keep counts of number of individuals at each class we can simply use these counts with a multinomial random function to do the sampling.

#### Selection
Selection is similar to drift, only the sampling procedure is now biased in favor of classes with higher fitness.

#### Mutation
Mutation changes one genome to another. We need to take an individual from a class and change it to another class.
The mutation rate sets the average number of mutations per genome per generation. The actual number is drawn from a Poisson distribution with the rate as the parameter. The mutations are uniformly distributed across the genome. A mutation changes the current allele to another one without bias - if there are only two alleles (diallelic model) than it changes 0 to 1 and 1 to 0, always. If there are three alleles (triallelic model) than 0 will change to 1 with probability 1/2 and to 2 with probability 1/2, and so on.

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

I (YR) started implementing the model in Python. R is also a possibility. Java is out of the question - to much overhead and not as fast. C/C++ is to much overhead. Matlab costs money (won't be able to use the entire computing power at hand) and is not open-source. 
The Python implementation uses Numpy and Scipy for manipulating the population attributes - these can be downloaded and installed from their website or using *pip*, but I recommend to install an [EPD] package, especially for installing on Windows 64-bit. If you want to i (contact me if you want it and can't find it). Other options for Windows 64-bit is [this page][64bit-python]. I believe 64-bit systems will have an advantage here because of the high computational power, but it can still be developed on 32-bit and depolyed on 64-bit, as it is Python...

[Yoav Ram]: http://www.yoavram.com/
[Hadany Evolutionary Theory Lab in Tel-Aviv]: http://sites.google.com/site/hadanylab/
[proevolutionsimulation]: http://proevolutionsimulation.googlecode.com/
[EPD]: http://www.enthought.com/products/epd.php
[64bit-python]: http://www.lfd.uci.edu/~gohlke/pythonlibs/

1: An allele is an instance of a gene. For example, at the homoglobin gene, which codes for the Homoglobin protein, which carries oxygen around the body, one could have a "good" allele that does a good job, and one can have a "bad" allele, that doesn't bind oxygen as good as the "good" allele, and therefore the person might suffer from breathing problems.