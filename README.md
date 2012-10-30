# Mamba

## Evolutionary simulations in R (and maybe Python) 

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

I (YR) started implementing the model in R. Java is out of the question - to much overhead and not as fast. C/C++ is to much overhead. Matlab costs money (won't be able to use the entire computing power at hand) and is not open-source. I implemented it in Python (see [python last commit], but it was too much work compared to R, with all those *NumPy* arrays. Also I think it was slower. 

The R implementation was coded on R v.2.15. The model uses the [e1071] package, the analysis uses the *ggplot2* and *plyr* packages. 

The results will be saved either using regular CSV files or using MongoDB. Probably CSV with gzip compression.

Initial *mutation-selection balance* analysis is written to analyze results of simulations reaching a balance.

### Version alfred

Version [alfred], named after [Alfred Russel Wallace][alfred-wallace], was sommited on 30/10/2012 and contains a working Wright-Fisher simulator with selection, drift, mutation and recombination (HGT). Also contains parameter file, overriding parameters from command line, writing output to CSV files, printing log messages to console, SGE file for batching jobs on an SGE cluster and code for mutation-selection balance analysis.

The next version, *baptiste*, will have an implementation of modifiers of mutation and recombination rates.

### Other tools

The code is hosted on [github]. 

The README was edited using [prose], an online text editor for github which allows to checkout and commit in a flouent way right from the browser and can be also used to deal with python files, although in a naive way. For markdown it's great as it have a preview and help panes.

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
