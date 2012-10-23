source("logic.r")

num.loci <- 1
pop.size <- 100000
s <- 0.1
target.genome <- rep(0, num.loci)

genomes <- t(matrix(target.genome))
genomes <- rbind(genomes, rep(1, num.loci))

num.strains <- dim(genomes)[1]
population <- rep(pop.size/num.strains, num.strains)
mu.rates <- rep(0.003, num.strains)
rec.rates <- c(0.00006, num.strains)

fitness <- apply(genomes, 1, hamming.fitness, s=s, target=target.genome)

mf <- weighted.mean(fitness, population)
tick <- 0
while(mf < (1-1/pop.size)) {
  # drift
  population <- genetic.drift(population, pop.size)
  
  # selection
  population <- selection(population, fitness, pop.size)
  
  # mean fitness
  mf <- weighted.mean(fitness, population)
  tick <- tick+1
}
sprintf("Finished at tick %d with mean fitness %f and class 0 size %d", tick, mf, population[1])