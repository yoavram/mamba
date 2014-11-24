library(data.table)
library(rjson)

today = Sys.Date()

load.log = function(x) {
  return(as.data.frame(suppressWarnings(fromJSON(file=x))))
}

load.data = function(x) {
  return(data.table(read.csv(x)))
}

files = list.files("~/workspace/mamba/output/mean_fitness", "*.csv.gz", full.names=T)

output = NULL
for (filename in files) {
  print(filename)
  log.filename = sub(".csv.gz", ".json", filename)
  log = load.log(log.filename)
  data = load.data(filename)
  fitness = data[, data.frame(mean.fitness=weighted.mean(fitness, population), max.fitness=max(fitness), min.fitness=min(fitness)), by="tick"]
  fitness = cbind(fitness, log)
  output = rbind(output, fitness)
}
write.csv(output, file=paste0("mean_fitness_",today,".csv"))
print("Done")
