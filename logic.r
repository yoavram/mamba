library(e1071)

hamming.fitness <- function(s, genome, target) {
  return((1-s)^hamming.distance(genome, target))
}

random.genome <- function(alleles=2, num.loci=100, prob.zero=0.99) {
  probs <- c(prob_zero, rep( (1-prob.zero)/(alleles-1), (alleles-1) ))  
  draw <- sample( seq(0,alleles), num.loci, T, probs)
  return(draw)
}

mean.fitness <- function(fitness, population) {
  mf <- as.numeric(a%*%b)
  return(mf)
}

genetic.drift <- function(population, pop.size=sum(population)) {
  draw <- rmultinom(1, pop.size, population)
  return(draw)
}

selection <- function(population, fitness, pop.size=sum(population)) {
  draw <- rmultinom(1, pop.size, population*fitness)
  return(draw)
}

frequencies <- function(population) {
  return(population/sum(population))
}

