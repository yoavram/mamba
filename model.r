library(e1071)

hamming.fitness <- function(s, genome, target) {
  return((1-s)^hamming.distance(genome, target))
}

random.genome <- function(alleles=2, num.loci=100, prob.zero=0.99) {
  probs <- c(prob_zero, rep( (1-prob.zero)/(alleles-1), (alleles-1) ))  
  draw <- sample( seq(0,alleles), num.loci, T, probs)
  return(draw)
}

debug <- FALSE
num.loci <- 100
pop.size <- 100000
s <- 0.01
mu.rate <- 0.003
rec.rate <- 0.00006
max.tick <- 10000
if (debug) {
  max.tick <- 5
  num.loci <- 3
}

target.genome <- rep(0, num.loci)

genomes <- t(matrix(target.genome))
num.strains <- dim(genomes)[1]
population <- rep(pop.size/num.strains, num.strains)
mu.rates <- rep(mu.rate, num.strains)
rec.rates <- c(rec.rate, num.strains)
fitness <- apply(genomes, 1, hamming.fitness, s=s, target=target.genome)

mf <- weighted.mean(fitness, population)
tick <- 0

if (debug) {
  pb <- txtProgressBar(min = 0, max = 1000, style = 3)
}

while(tick < max.tick) {
  # drift
  population <- rmultinom(1, pop.size, population)
  
  # selection
  population <- rmultinom(1, pop.size, population*fitness)
  
  # mutation
  mutations <- rpois(num.strains, mu.rates*population)
  mutations.cum <- cumsum(mutations)
  loci <- sample( num.loci, sum(mutations), T )
  #strains <- unlist(Map(function(x) which.max( mutations.cum>=x ), seq_along(loci)))
  for (i in seq_along(loci)) {
    locus <- loci[i]
    strain <- which.max( mutations.cum>=i )
    # create mutated genome
    genome <- genomes[strain,]
    genome[locus] <- (genome[locus]+1)%%2
    
    # find if new genome already exists
    new_strain <- -1
    for (i in 1:num.strains) {
      # this is faster than apply, and not just because there is a stop condition
      if (all(genomes[i,]==genome)) {
        new_strain <- i
        break
      }
    }
    if (new_strain == -1) {
      # add new strain
      genomes <- rbind(genomes, genome)
      num.strains <- num.strains + 1
      new_strain <- num.strains
      mu.rates <- c(mu.rates, mu.rate) # TODO
      rec.rates <- c(mu.rates, rec.rate) # TODO
      fitness <- c(fitness, hamming.fitness(s, genome, target.genome))
      population <- c(population, 1)
    } else {
      # increment number of individual in new strain
      population[new_strain] <- population[new_strain] + 1
    }
    # decrement number of individuals in mutated strain
    population[strain] <- population[strain] - 1
  }
  
  # clear empty strains
  strains <- which(population>0)
  if (length(strains)>(num.strains/10)) {
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
  tick <- tick+1
  if (debug) {
    setTxtProgressBar(pb, tick)
  }
  if (tick%%100==0) {
    sprintf("Tick %d mean fitness %f number of strains %d", tick, mf, num.strains)
  }
}

sprintf("Finished at tick %d with mean fitness %f and number of strains %d", tick, mf, num.strains)
if (debug) {
  close(pb)
}

# clear empty strains
strains <- which(population>0)
population <- population[strains]
genomes <- genomes[strains,]
mu.rates <- mu.rates[strains]
rec.rates <- rec.rates[strains]
fitness <- fitness[strains]
num.strains <- length(population)

df <- data.frame(count=population, fitness=fitness, mutation.load=apply(genomes,1,sum), mu.rates=mu.rate, rec.rates=rec.rates)
fname <- paste("output/mamba_",strftime(Sys.time(),format="%Y_%b_%d_%H_%M_%s"),".csv", sep="")
write.csv(df, fname)

