source("common.R")

first.ratchet.click <- function(agg.data) {
  first.click <- min(which(agg.data$max.fitness<1))
  if (is.infinite(first.click)){
    first.click = max(agg.data$tick)
  } else {
    first.click <- agg.data$tick[first.click]
  }
  return(first.click)
}

plot.first.click.distr <- function(df, title='') {
  q <- ggplot(data=df, mapping=aes(x=factor(pop_size), y=first.click))
  q <- q + geom_boxplot(outlier.size=0, alpha=I(0))
  q <- q + geom_jitter(aes(color=factor(pop_size)))
  q <- q + facet_grid(facets=pi~tau, scale="free_y") 
  q <- q +
    xlab("Population size") + 
    ylab("Time to first ratchet click") + 
    ggtitle(paste("Tau/Pi", title)) +
    scale_color_brewer(guide="none", palette="Set1") +
    scale_y_log10()
  return(q)
}

plot.fitness <- function(data) {
  metled <- melt(data, id.vars="tick")
  p <- ggplot(melted, aes(x=tick, y=value, group=variable)) +
    geom_line(colour=variable) +
    coord_cartesian(xlim=c(0,1000)) + 
    scale_color_brewer(palette="Set1")
  return(p)
}

aggregate.fitness <- function(data) {
  df <- ddply(data, .(tick, fitness), summarize,
    count = sum(population)
  )
  df2 <- ddply(df, .(tick), summarize,
    mean.fitness = weighted.mean(fitness, count),
    mean.sq.fitness = weighted.mean(fitness^2, count),               
    min.fitness = min(fitness),
    max.fitness = max(fitness)
  )
  df2$var.fitness <- df2$mean.sq.fitness - df2$mean.fitness^2
  return(df2)
}

sge.aggregate.fitness <- function() {
  # this is used to take output of the simulation and create a table of fitness population
  # aggregates, such as min max mean variance, for each tick.
  files <- load.files.list("shaw2011")
  
  library(Rsge)
  sge.options(sge.qsub.options="-cwd -V -l lilach")
  sge.options(sge.remove.files=T)
  
  res <- sge.parLapply(files, function(filename) {
    outname <- paste0("output/shaw2011/fitness.", filename, ".csv")
    if (!file.exists(outname)) {
      data <- load.data("shaw2011", filename)
      fitness <- aggregate.fitness(data)
      write.csv(fitness, file=outname)
    }
  }, 
  njobs=500, 
  global.savelist=c("aggregate.fitness","load.data"), 
  packages=c("stringr","plyr"))
}

combine.fitness <- function() {
  # this code is used to take the fitness aggregates files and combine them into one file
  # adding all the params so that the new file can be used with ddply to calculate and
  # plot fitness statistics
  
  #library(Rsge)
  files = load.files.list("shaw2011")
  
  sge.options(sge.qsub.options="-cwd -V -l lilach")
  sge.options(sge.remove.files=T)
  
  fitness.data <- sge.parLapply(files, function(filename) {
    params <- load.params("shaw2011", filename)
    data <- load.fitness.data("shaw2011", filename)
    if (is.null(data)) {
      return(NULL)
    }
    if (nrow(data) != 1001) {
      return(NULL)
    }
    data <- cbind(data,params)
    return(data)
    }, 
    global.savelist=c("load.fitness.data","load.params"),
    packages=c("stringr","plyr", "rjson"),
    cluster=FALSE,
    njobs=500)
  
  fitness.data <- do.call("rbind", fitness.data)
  save(fitness.data, file=paste0("ijee2013/fitness.data.", datetime.string(), ".RData"))

}
## this code generates a plot from the fitness.data

plot.mean.fitness <- function(fitness.data) {
  p <- ggplot(fitness.data,aes(x=tick, y=mean.fitness))
  p2 <- p + 
    geom_point(mapping=aes(group=factor(pop_size), color=factor(beta), alpha=factor(r))) + 
    facet_grid(facets=tau~pi)
  return(p2)
}


                                                                                    