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

#### Fitness
Fitness



[Yoav Ram]: http://www.yoavram.com/
[Hadany Evolutionary Theory Lab in Tel-Aviv]: http://sites.google.com/site/hadanylab/
[proevolutionsimulation]: http://proevolutionsimulation.googlecode.com/

1: An allele is an instance of a gene. For example, at the homoglobin gene, which codes for the Homoglobin protein, which carries oxygen around the body, one could have a "good" allele that does a good job, and one can have a "bad" allele, that doesn't bind oxygen as good as the "good" allele, and therefore the person might suffer from breathing problems.