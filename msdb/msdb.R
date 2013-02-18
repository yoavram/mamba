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

aggregate.mutation.rate <- function(data) {
  df <- ddply(data, .(tick, mutation_rates), summarize,
              count = sum(population)
  )
  df2 <- ddply(df, .(tick), summarize,
               mean.mutation.rate = weighted.mean(mutation_rates, count),
               mean.sq.mutation.rate = weighted.mean(mutation_rates^2, count),               
               min.mutation.rate = min(mutation_rates),
               max.mutation.rate = max(mutation_rates)
  )
  df2$var.mutation.rate <- df2$mean.sq.mutation.rate - df2$mean.mutation.rate^2
  return(df2)
}

plot.fitness.and.mutation.rate.for.single.run(filename) {
  library(reshape2)
  data<-load.data("shaw2011", filename)
  df.mu<-aggregate.mutation.rate(data)
  df.fitness<-aggregate.fitness(data)
  melt.mu <- melt(data=df.mu, measure.vars=c("mean.mutation.rate","max.mutation.rate", "min.mutation.rate"))
  melt.fitness<- melt(data=df.fitness, measure.vars=c("mean.fitness","max.fitness", "min.fitness"))
  q1=qplot(tick,value,data=melt.mu, color=variable, size=1)
  q2=qplot(tick,value,data=melt.fitness, color=variable, size=1)
  return(grid.arrange(q1,q2,main=filename))
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
    if (is.null(params)) {
      return(NULL)
    }
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

plot.mean.fitness <- function(mean.fitness) {
  p <- ggplot(mean.fitness, aes(x=tick, y=mean.fitness))
  p2 <- p + 
    geom_point(mapping=aes(group=factor(pop_size), color=factor(pop_size), alpha=factor(r)), size=1) + 
    facet_grid(facets=pi+tau~beta)
  return(p2)
}

plot.max.fitness <- function(mean.fitness) {
  p <- ggplot(mean.fitness, aes(x=tick, y=max.fitness))
  p2 <- p + geom_point(aes(color=paste0('Tau',as.character(tau),'Pi',as.character(pi)))) + 
    facet_grid(r~beta) + 
    scale_color_brewer(palette="Set1", name="Mutator") +
    geom_hline(yintercept)
  return(p2)
}

mean.fitness.data <- function(filename) {
  load(paste0("ijee2013/",filename,".RData"))
  fitness.mean <- ddply(fitness.data, .(pop_size, beta, r, pi, tau, tick), summarize,
                        N = length(mean.fitness),
                        mean.fitness = mean(mean.fitness),
                        max.fitness = mean(max.fitness),
                        min.fitness = mean(min.fitness),
                        var.fitness = mean(var.fitness)
  )
  write.csv(fitness.mean, file=paste0("ijee2013/mean.",filename,".csv"))
  return(fitness.mean)
}


                                                                                    