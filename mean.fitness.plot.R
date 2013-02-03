source("common.R")

plot.mean.fitness <- function(filename, return.plot=T, save.to.file=T) {
  params <- load.params(filename)
  data <- load.data(filename)
  
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
    plot.filename <- str_c('output/', filename, '/mean-fitness.', filename, ".png")
    dir.create(dirname(plot.filename), showWarnings = FALSE)
    ggsave(filename=plot.filename, plot=p)
  }
  
  if (return.plot){
    return(p)
  } else{
    return(NULL)
  }
}

plot.tau.frequency <- function(filename, return.plot=T, save.to.file=T) {
  params <- load.params(filename)
  data <- load.data(filename)
  data$tau <- factor(data$tau)
  df <- ddply(data, .(tick, tau), summarize, 
              frequency = sum(population)/params$pop_size
  )
  
  p <- qplot(x=tick, y=frequency, data=df, geom="line", color=tau, group=tau)
  title <- str_c(filename,"\n", "pop_size",params$pop_size,"s",params$s,"mu",params$mu,"r",params$r, "in_rate", params$in_rate, "in_tick", params$in_tick, "\n",
                 "resident:","pi",params$pi,"tau",params$tau,"phi",params$phi,"rho",params$rho, "\n",
                 "invader:","pi",params$in_pi,"tau",params$in_tau,"phi",params$in_phi,"rho",params$in_rho, sep=" " )
  p <- p + ggtitle(title)
  p <- p + xlab('Generations') + ylab("Frequency")
  p <- p + geom_vline(x=as.numeric(as.character(params$in_tick)), colour="black", size=0.4)

  if (save.to.file) {
    plot.filename <- str_c('output/', filename, '/tau-freq.', filename, ".png")
    dir.create(dirname(plot.filename), showWarnings = FALSE)
    ggsave(filename=plot.filename, plot=p)
  }
  if (return.plot){
    return(p)
  } else{
    return(NULL)
  }
}

files <- load.files.list()
lapply(files, plot.mean.fitness, return.plot=F, save.to.file=T)
lapply(files, plot.tau.frequency, return.plot=F, save.to.file=T))