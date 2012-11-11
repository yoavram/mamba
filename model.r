source('params.r')
source('../R/rcommon/tictoc.R')
library(e1071)
library(logging)

setup.logging <- function() {
  logReset() 
  if (debug) {
    addHandler(writeToConsole, level=9, file=log.fname)
  } else {
    addHandler(writeToConsole, level=30, file=log.fname)
  }
  addHandler(writeToFile, level=9, file=log.fname)
}

stats.to.dataframe <- function() {
  # TODO add modifier stats
  df <- data.frame( tick=rep(tick, num.strains), strain=apply(genomes, 1, genome.to.int), population=population, fitness=fitness, mutation.load=apply(genomes, 1, hamming.distance, target.genome), mu.rates=mu.rates, rec.rates=rec.rates)
  return(df)
}

hamming.fitness <- function(genome) {
  return((1-s)^hamming.distance(genome, target.genome))
}

mutation.rate <- function(genome, modifier) {
  load <- hamming.distance(genome, target.genome)
  if (load >= modifier$pi) {
    return(mu.rate*modifier$tau)
  } else{
    return(mu.rate)
  }
}

mutation.rate.for.strain <- function(strain) {
  x <- mutation.rate(genomes[strain,], modifiers[strain,])
  return(x)
}

recombination.rate <- function(genome, modifier) {
  load <- hamming.distance(genome, target.genome)
  if (load >= modifier$phi) {
    return(rec.rate*modifier$rho)
  } else{
    return(rec.rate)
  }
}

recombination.rate.for.strain <- function(strain) {
  x <- recombination.rate(genomes[strain,], modifiers[strain,])
  return(x)
}

stats.to.dataframe <- function() {
  df <- data.frame( tick=rep(tick, num.strains), strain=apply(genomes, 1, genome.to.int), population=population, fitness=fitness, mutation.load=apply(genomes, 1, hamming.distance, target.genome), mu.rates=mu.rates, rec.rates=rec.rates)
  return(df)
}

genome.to.int <- function(genome) {
  s <- 0
  for (i in 1:length(genome)) {
    s <- s + num.alleles^(i-1) * genome[i]
  }
  return(s)
}

save.model <- function(filename) {
  save.list <- c('genomes', 'modifiers', 'population', 'target.genome', 'fitness', 'mu.rates', 'rec.rates', 'num.loci', 'num.strains', 'pop.size', 's', 'mu.rate', 'rec.rate' )
  save(list = save.list, file = filename)
}

load.model <- function(filename, envir=parent.frame()) {
  load(file=filename, envir=envir)
}

dump(params, log.fname)
setup.logging()
tic()

if (debug) {
  loginfo("Running in debug mode")
  max.tick <- 100
  num.loci <- 5
}

if (file.exists(start.fname)) {
  load.model(start.fname)
  loginfo(sprintf("Loaded model %s", start.fname))
} else {
  target.genome <- rep(0, num.loci)
  
  genomes <- t(matrix(target.genome))
  modifiers <- data.frame(pi=1, tau=10, phi=Inf, rho=1) # pi, tau, phi, rho
  
  num.strains <- dim(genomes)[1]
  population <- rep(pop.size/num.strains, num.strains)
  mu.rates <- sapply(1:num.strains, mutation.rate.for.strain)
  rec.rates <- sapply(1:num.strains, recombination.rate.for.strain)
  fitness <- apply(genomes, 1, hamming.fitness)
}

env.changes <- rbinom(n=max.tick, size=1, prob=env.change.freq)==1
mf <- weighted.mean(fitness, population)
tick <- 0
output.df <- stats.to.dataframe()

# Start simulation loop
loginfo(sprintf("Starting %s simulation\n", job.name))

while(tick < max.tick) {
  tick  <- tick + 1
  
  # drift
  population <- rmultinom(1, pop.size, population)
  
  # selection
  population <- rmultinom(1, pop.size, population*fitness)
  
  # mutation + recombination
  events <- rpois(num.strains, (rec.rates+mu.rates)*population)
  events.cum <- cumsum(events)
  loci <- sample( num.loci, sum(events), T )
  p.mu <- mu.rates/(mu.rates + rec.rates) # the prob that an event is a mutation and not a recombination
  mutations <- rbinom(length(events), events, p.mu)
  mutation.threshold <- sapply(1:num.strains, function(x){
    if (x==1) return(mutations[x]) else return(mutations[x]+events.cum[x-1])
    })
  recombinations <- events-mutations
  donors <- sample(num.strains, sum(recombinations), replace=T, prob=population)
  
  for (i in seq_along(loci)) {
    locus <- loci[i]
    strain <- which.max( events.cum>=i )
    # create new genome
    genome <- genomes[strain,]
    
    # mutation or recombination?
    
    if (i <= mutation.threshold[strain]) {
      # mutation - TODO more alleles
      genome[locus] <- (genome[locus]+1)%%num.alleles # TODO do I need to draw or is +1 good enough?
    } else {
      # recombination
      rec.i <- i - mutation.threshold[strain]
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
      modifiers <- rbind(modifiers, modifiers[strain,])
      num.strains <- num.strains + 1
      new.strain <- num.strains
      mu.rates <- c(mu.rates, mutation.rate.for.strain(new.strain)) 
      rec.rates <- c(rec.rates, recombination.rate.for.strain(new.strain)) 
      fitness <- c(fitness, hamming.fitness(genome))
      population <- c(population, 1)
    } else {
      # increment number of individual in new strain
      population[new.strain] <- population[new.strain] + 1
    }
    # decrement number of individuals in mutated strain
    population[strain] <- population[strain] - 1
  }
  
  # environmental changes
  if (env.changes[tick]) {
    changed.loci <- sample(x=num.loci, size=num.loci.to.change, replace=F)
    allele.incr <- sample(x=(num.alleles-1), size=num.loci.to.change, replace=T)
    target.genome[changed.loci] <- (target.genome[changed.loci] + allele.incr) %% num.alleles
    fitness <- apply(genomes, 1, hamming.fitness)
  }
  
  # clear empty strains
  strains <- which(population>0) # the non-empty strains
  fraction.non.empty <- length(strains)/num.strains
  if (fraction.non.empty < min.non.empty.fraction) {
    population <- population[strains]
    genomes <- genomes[strains,]
    modifiers <- modifiers[strains,]
    mu.rates <- mu.rates[strains]
    rec.rates <- rec.rates[strains]
    fitness <- fitness[strains]
    num.strains <- length(population)
  }  
  
  # mean fitness
  mf <- weighted.mean(fitness, population)
  
  # finish step
  
  if (tick %% tick.interval == 0) {
    loginfo(sprintf("Tick %d mean fitness %f number of strains %d\n", tick, mf, num.strains))
  }
  if (tick %% stats.interval == 0 ) {
    output.df <- rbind(output.df, stats.to.dataframe())
  }
}

loginfo(sprintf("Finished at tick %d with mean fitness %f and number of strains %d\n", tick, mf, num.strains))

strains <- which(population>0) # the non-empty strains
fraction.non.empty <- length(strains)/num.strains
if (fraction.non.empty < 1) {
  population <- population[strains]
  genomes <- genomes[strains,]
  modifiers <- modifiers[strains,]
  mu.rates <- mu.rates[strains]
  rec.rates <- rec.rates[strains]
  fitness <- fitness[strains]
  num.strains <- length(population)
}

if (tick %% stats.interval != 0 ) {
  # save last tick if it wasn't saves
 output.df <- rbind(output.df, stats.to.dataframe())
}
write.csv(output.df, output.fname, row.names=F)
loginfo(sprintf("Output written to %s\n", output.fname))

save.model(filename=ser.fname)
loginfo(sprintf("Model saved to %s\n", ser.fname))

loginfo(sprintf("Simulation time: %f seconds", toc()))
