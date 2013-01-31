library(ggplot2)
library(plyr)
library(rjson)
library(tools)
library(stringr)

load.params <- function(filename) {
  params <- fromJSON(file=str_c('output/', filename, '/', filename, ".json"))
  return(params)
}

plot.mean.fitness <- function(filename, save.to.file=T) {
  params <- load.params(filename)
  data <- read.csv(str_c('output/', filename, '/', filename, '.csv.gz'),header=T)
  
  df <- ddply(data, .(tick, fitness), summarize, 
              count = sum(population)
  )
  df2 <- ddply(df, .(tick), summarize, 
               mean.fitness = weighted.mean(fitness, count)
  )
  p <- qplot(x=tick, y=log(mean.fitness), data=df2, geom=c("point","line"))
  p <- p + ggtitle(paste(filename, paste("pop",params$pop_size,"s",params$s,"mu",params$mu,"r",params$r,"pi",params$pi,"tau",params$tau,"phi",params$phi,"rho",params$rho,"r"),sep="\n"))
  p <- p + xlab('Generations') + ylab("Log Mean Fitness")
  p <- p + geom_hline(y=-as.numeric(as.character(params$mu)), colour="blue")
  
  if (save.to.file) {
    plot.filename <- str_c('output/', filename, '/', filename, ".png")
    dir.create(dirname(plot.filename), showWarnings = FALSE)
    ggsave(filename=plot.filename, plot=p)
  }
  
  return(p)
}

files <- dir(path="output/",pattern="*")
files <- files[files!='tmp']
lapply(files, plot.mean.fitness)