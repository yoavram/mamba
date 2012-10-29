source('params.r')
library(e1071)

hamming.fitness <- function(s, genome, target) {
  return((1-s)^hamming.distance(genome, target))
}

random.genome <- function(alleles=2, num.loci=100, prob.zero=0.99) {
  probs <- c(prob_zero, rep( (1-prob.zero)/(alleles-1), (alleles-1) ))  
  draw <- sample( seq(0,alleles), num.loci, T, probs)
  return(draw)
}

stats.to.dataframe <- function() {
  df <- data.frame(count=population, fitness=fitness, mutation.load=apply(genomes, 1, sum), mu.rates=mu.rate, rec.rates=rec.rates)
  return(df)
}

if (debug) {
  max.tick <- 10
  num.loci <- 30
}

target.genome <- rep(0, num.loci)

genomes <- t(matrix(target.genome))
if (debug) {
  new.genome <- genomes[1,]
  new.genome[1] <- 1
  genomes <- rbind(genomes, new.genome)
}

num.strains <- dim(genomes)[1]
population <- rep(pop.size/num.strains, num.strains)
mu.rates <- rep(mu.rate, num.strains)
rec.rates <- rep(rec.rate, num.strains)
fitness <- apply(genomes, 1, hamming.fitness, s=s, target=target.genome)

mf <- weighted.mean(fitness, population)
tick <- 0

if (debug) {
  pb <- txtProgressBar(min = 0, max = 1000, style = 3)
}

cat(sprintf("Starting %s simulation\n", job.name))

while(tick < max.tick) {
  # drift
  population <- rmultinom(1, pop.size, population)
  
  # selection
  population <- rmultinom(1, pop.size, population*fitness)
  
  # mutation+recombination
  events <- rpois(num.strains, (rec.rates+mu.rates)*population)
  events.cum <- cumsum(events)
  loci <- sample( num.loci, sum(events), T )
  p.mu <- mu.rates/(mu.rates + rec.rates) # the prob that an event is a mutation and not a recombination
  mutations <- rbinom(length(events), events, p.mu)
  mutations.cum <- cumsum(mutations)
  recombinations <- events-mutations
  donors <- sample(num.strains, sum(recombinations), replace=T, prob=population)
  
  for (i in seq_along(loci)) {
    locus <- loci[i]
    strain <- which.max( events.cum>=i )
    # create new genome
    genome <- genomes[strain,]
    
    # mutation or recombination?
    if (i <= mutations.cum[strain]) {
      # mutation - TODO more alleles
      genome[locus] <- (genome[locus]+1)%%2
    } else {
      # recombination
      rec.i <- i - mutations.cum[strain]
      donor <- donors[rec.i]
      genome[locus] <- genomes[donor, locus]
    }
    
    # find if new genome already exists
    new.strain <- -1
    for (i in 1:num.strains) {
      # this is faster than apply, and not just because there is a stop condition
      if (all(genomes[i,]==genome)) {
        new.strain <- i
        break
      }
    }
    if (new.strain == -1) {
      # add new strain
      genomes <- rbind(genomes, genome)
      num.strains <- num.strains + 1
      new.strain <- num.strains
      mu.rates <- c(mu.rates, mu.rate) # TODO
      rec.rates <- c(rec.rates, rec.rate) # TODO
      fitness <- c(fitness, hamming.fitness(s, genome, target.genome))
      population <- c(population, 1)
    } else {
      # increment number of individual in new strain
      population[new.strain] <- population[new.strain] + 1
    }
    # decrement number of individuals in mutated strain
    population[strain] <- population[strain] - 1
  }
  
  # clear empty strains
  strains <- which(population>0) # the non-empty strains
  fraction.non.empty <- length(strains)/num.strains
  if (fraction.non.empty < min.non.empty.fraction) {
    population <- population[strains]
    genomes <- genomes[strains,]
    mu.rates <- mu.rates[strains]
    rec.rates <- rec.rates[strains]
    fitness <- fitness[strains]
    num.strains <- length(population)
  }  
  
  # mean fitness
  mf <- weighted.mean(fitness, population)
  
  # finish step
  tick <- tick + 1
  if (debug) {
    setTxtProgressBar(pb, tick)
  }
  if (tick %% tick.interval==0) {
    cat(sprintf("Tick %d mean fitness %f number of strains %d\n", tick, mf, num.strains))
  }
}

cat(sprintf("Finished at tick %d with mean fitness %f and number of strains %d\n", tick, mf, num.strains))
if (debug) {
  close(pb)
}

strains <- which(population>0) # the non-empty strains
fraction.non.empty <- length(strains)/num.strains
if (fraction.non.empty < 1) {
  population <- population[strains]
  genomes <- genomes[strains,]
  mu.rates <- mu.rates[strains]
  rec.rates <- rec.rates[strains]
  fitness <- fitness[strains]
  num.strains <- length(population)
}

df <- stats.to.dataframe()
write.csv(df, output.fname, row.names=F)
cat(sprintf("Output written to %s\n", output.fname))

