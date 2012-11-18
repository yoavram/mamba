source('params.r')
source('model.r')
source('../R/rcommon/tictoc.R')
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

set.seed.alpha <- function(x) {
  require("digest")
  hexval <- paste0("0x",digest(x,"crc32"))
  intval <- type.convert(hexval) %% .Machine$integer.max
  set.seed(intval)
}

population.stats <- function(population) {
  return(cbind( tick=rep(tick, nrow(population)), population))
}

#### START HERE #####

dump(params, log.fname)
setup.logging()
set.seed.alpha(paste(job.id, job.name))
tic()

if (file.exists(start.fname)) {
  load.model(start.fname)
}
else {
  target.genome <- default.target.genome()
  population <- create.population()
}

if (invasion.rate>0) {
  # TODO invasion
}

env.changes <- draw.environmental.changes()
mf <- mean.fitness(population)
tick <- 0
output.df <- population.stats(population)

if (phylogeny) {
  source("tree.R")
  strains <- as.character(apply(genomes, 1, genome.to.int))
  tree <- create.initial.tree(strains)
}

loginfo(sprintf("Starting %s simulation\n", job.name))

while (tick <- max.tick) {
  tick <- tick + 1
  
  population <- genetic.drift(population)
  population <- selection(population)
  population <- mutation.recombination(population)
  
  if (env.changes[tick]) {
    target.genome <- environmental.change()
    population$fitness <- apply(population[,1:num.loci], 1, hamming.fitness)
  }
  
  population <- clear.empty.strains(population)
  
  mf <- mean.fitness(population)
  
  if (tick %% tick.interval == 0) {
    loginfo(sprintf("Tick %d mean fitness %f number of strains %d\n", tick, mf, nrow(population)))
  }
  if (tick %% stats.interval == 0 ) {
    output.df <- rbind(output.df, population.stats(population))
  }
}

loginfo(sprintf("Finished at tick %d with mean fitness %f and number of strains %d\n", tick, mf, num.strains))

if (phylogeny) {
  save(tree, file=tree.fname)
  loginfo(sprintf("Phylogeny written to %s\n", tree.fname))
}

if (tick %% stats.interval != 0 ) {
  # save last tick if it wasn't saves
  output.df <- rbind(output.df, population.stats(population))
}
write.csv(output.df, output.fname, row.names=F)
loginfo(sprintf("Output written to %s\n", output.fname))

save.model(filename=ser.fname)
loginfo(sprintf("Model saved to %s\n", ser.fname))

loginfo(sprintf("Simulation time: %f seconds", toc()))
