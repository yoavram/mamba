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
  title <- str_c(filename,"\n", "pop_size",params$pop_size,"s",params$s,"mu",params$mu,"r",params$r, "in_rate", params$in_rate, "in_tick", params$in_tick, "\n",
                 "resident:","pi",params$pi,"tau",params$tau,"phi",params$phi,"rho",params$rho, "\n",
                 "invader:","pi",params$in_pi,"tau",params$in_tau,"phi",params$in_phi,"rho",params$in_rho, sep=" " )
  p <- p + ggtitle(title)
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