library(e1071)

load.model <- function(start.fname) {
  load(file=filename, envir=envir)
}

save.model <- function(filename) {
  save.list <- c('population', 'target.genome', 'num.loci', 'num.alleles', 'pop.size', 's', 'mu.rate', 'rec.rate' )
  save(list = save.list, file = filename)
}

hamming.fitness <- function(genome) {
  return((1-s)^hamming.distance(genome, target.genome))
}

mutation.rate <- function(genome, pi, tau) {
  load <- hamming.distance(genome, target.genome)
  if (load >= pi) {
    return(mu.rate * tau)
  } else{
    return(mu.rate)
  }
}

mutation.rate.for.strain <- function(strain.row) {
  genome <- strain.row[1:num.loci]
  pi <- strain.row$pi
  tau <- strain.row$tau
  return(mutation.rate(genome, pi, tau))
}

recombination.rate <- function(genome, phi, rho) {
  load <- hamming.distance(genome, target.genome)
  if (load >= phi) {
    return(rec.rate * rho)
  } else{
    return(rec.rate)
  }
}

recombination.rate.for.strain <- function(strain.row) {
  genome <- strain.row[1:num.loci]
  phi <- strain.row$phi
  rho <- strain.row$rho
  return(recombination.rate(genome, phi, rho))
}


genome.to.int <- function(genome) {
  s <- 0
  for (i in 1:length(genome)) {
    s <- s + num.alleles^(i-1) * genome[i]
  }
  return(s)
}

default.target.genome <- function() {
  return(rep(0, num.loci))
}

create.population <- function() {
  genomes <- t(matrix(target.genome))
    
  modifiers <- data.frame(pi=Inf, tau=10, phi=Inf, rho=1)
  
  count <- rep(pop.size/nrow(genomes), nrow(genomes))
  strain <- apply(genomes, 1, genome.to.int)
  fitness <- apply(genomes, 1, hamming.fitness)
    
  mu.rates <- apply(genomes, 1, mutation.rate, pi=Inf, tau=1)
  rec.rates <- apply(genomes, 1, recombination.rate, phi=Inf, rho=1)
  
  population <- cbind(genomes, strain, count, modifiers, fitness, mu.rates, rec.rates)
  
  return(population)
}

create.two.strain.population <- function() {
  genomes <- t(matrix(target.genome))
  genomes <- rbind(genomes, rep(1,num.loci))
    
  modifiers <- data.frame(pi=Inf, tau=10, phi=Inf, rho=1)
  modifiers <- rbind(modifiers, modifiers)
  
  count <- rep(pop.size/nrow(genomes), nrow(genomes))
  strain <- apply(genomes, 1, genome.to.int)
  fitness <- apply(genomes, 1, hamming.fitness)
  
  mu.rates <- apply(genomes, 1, mutation.rate, pi=Inf, tau=1)
  rec.rates <- apply(genomes, 1, recombination.rate, phi=Inf, rho=1)
  
  population <- cbind(genomes, strain, count, modifiers, fitness, mu.rates, rec.rates)
  
  return(population)
}

mean.fitness <- function(population) {
  return(weighted.mean(population$fitness, population$count))
}

draw.environmental.changes <- function() {
  changes <- rbinom(n=max.tick, size=1, prob=env.change.freq)==1
  return(changes)
}

genetic.drift <- function(population) {
  population$count <- rmultinom(1, pop.size, population$count)
  return(population)
}

selection <- function(population) {
  population$count <- rmultinom(1, pop.size, population$count * population$fitness)
  return(population)
}

mutation.recombination <- function(population) {
  events <- rpois(nrow(population), (population$rec.rates + population$mu.rates) * population$count)
  events.cum <- cumsum(events)
  loci <- sample( num.loci, sum(events), T )
  p.mu <- population$mu.rates/(population$mu.rates + population$rec.rates) # the prob that an event is a mutation and not a recombination
  mutations <- rbinom(length(events), events, p.mu)
  mutation.threshold <- sapply(1:nrow(population), function(x){
    if (x==1) return(mutations[x]) else return(mutations[x] + events.cum[x-1])
  })
  recombinations <- events-mutations
  donors <- sample(nrow(population), sum(recombinations), replace=T, prob=population$count)
  
  for (i in seq_along(loci)) {
    locus <- loci[i]
    strain <- which.max( events.cum>=i )
    # create new genome
    genome <- as.numeric(population[strain, 1:num.loci])
    
    # mutation or recombination?
    
    if (i <= mutation.threshold[strain]) {
      # mutation - TODO more alleles
      genome[locus] <- (genome[locus]+1)%%num.alleles # TODO do I need to draw or is +1 good enough?
    } else {
      # recombination
      rec.i <- i - mutation.threshold[strain]
      donor <- donors[rec.i]
      genome[locus] <- population[donor, locus]
    }
    
    # find if new genome already exists
    new.strain <- -1
    for (i in 1:nrow(population)) {
      # this is faster than apply, and not just because there is a stop condition
      if (all(as.numeric(population[i, 1:num.loci])==genome)) {
        new.strain <- i
        break
      }
    }
    if (new.strain == -1) {
      # add new strain
      modifiers <- population[strain, c("pi","tau","phi","rho")]
      strain.row <- unlist(c(genome, genome.to.int(genome), 1, modifiers, hamming.fitness(genome), mutation.rate(genome, modifiers$pi, modifiers$tau), recombination.rate(genome, modifiers$phi, modifiers$rho)))
      population <- rbind(population, strain.row)
      if (phylogeny) {
        tree <- add.strain(tree, as.character(genome.to.int(population[new.strain, 1:num.loci])), as.character(genome.to.int(genomes[strain,])))
      }
    } else {
      # increment number of individual in new strain
      population[new.strain, ]$count <- population[new.strain, ]$count + 1
    }
    # decrement number of individuals in mutated strain
    population[strain, ]$count <- population[strain, ]$count - 1
  }
  return(population)
}

environmental.change <- function() {
  changed.loci <- sample(x=num.loci, size=num.loci.to.change, replace=F)
  allele.incr <- sample(x=(num.alleles-1), size=num.loci.to.change, replace=T)
  target.genome[changed.loci] <- (target.genome[changed.loci] + allele.incr) %% num.alleles
  return(target.genome)
}

clear.empty.strains <- function(population) {
  strains <- which(population$count > 0) # the non-empty strains
  population <- population[strains, ]
  return(population)
}