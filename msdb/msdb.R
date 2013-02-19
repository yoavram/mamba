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

plot.fitness.and.mutation.rate.for.single.run <- function(filename) {
  library(reshape2)
  data<-load.data("shaw2011", filename)
  df.mu<-aggregate.mutation.rate(data)
  df.fitness<-aggregate.fitness(data)
  melt.mu <- melt(data=df.mu, measure.vars=c("mean.mutation.rate","max.mutation.rate", "min.mutation.rate"))
  melt.fitness<- melt(data=df.fitness, measure.vars=c("mean.fitness","max.fitness", "min.fitness"))
  q1=qplot(tick,log(value),data=melt.mu, color=variable, size=I(1.5), geom="point")
  q2=qplot(tick,log(value),data=melt.fitness, color=variable, size=I(1.5), geom="point")
  q3=grid.arrange(q1,q2,main=filename)
  return(q3)
}


plot.fitness.jitter <- function(data) {
  pop.size <- sum(subset(data, tick==0)$population)
  d <- subset(data, tick==1 | (tick%%500==0 & tick>0))
  dd <- ddply(d, .(tick, fitness), summarize, frequency=sum(population)/pop.size)
  q <- 
    qplot(tick, log(fitness), data=dd, group=tick,size=frequency, geom=c("jitter"))
  return(q)
}

plot.fitness.histogram.timeseries <- function(data) {
  pop.size <- sum(subset(data, tick==0)$population)
  d <- subset(data, tick==1 | (tick%%1000==0 & tick>0))
  dd <- ddply(d, .(tick, fitness), summarize, frequency=sum(population)/pop.size)
  p <- ggplot(dd,aes(x=log(fitness), y=frequency, fill=factor(tick))) + 
    geom_density(stat="identity", alpha=.7, color=0, position = "identity") +
    scale_fill_brewer(palette="Set1")
  return(p)
}

sge.aggregate.fitness <- function() {
  # this is used to take output of the simulation and create a table of fitness population
  # aggregates, such as min max mean variance, for each tick.
  files <- load.files.list("shaw2011")
  
  library(Rsge)
  sge.options(sge.qsub.options="-cwd -V -l lilach")
  sge.options(sge.remove.files=T)
  
  res <- sge.parLapply(files, function(filename) {
    fitness.outname <- paste0("output/shaw2011/fitness.", filename, ".csv")
    mutation.rate.outname <- paste0("output/shaw2011/mutation.rate.", filename, ".csv")
    data <- NULL
    if (!file.exists(fitness.outname)) {
      data <- load.data("shaw2011", filename)
      fitness.df <- aggregate.fitness(data)
      write.csv(fitness.df, file=fitness.outname)
    }
    if (!file.exists(mutation.rate.outname)) {
      if (is.null(data)) {
        data <- load.data("shaw2011", filename)
      }
      mutation.rate.df <- aggregate.mutation.rate(data)
      write.csv(mutation.rate.df, file=mutation.rate.outname)
    }
  }, 
  njobs=500, 
  global.savelist=c("aggregate.fitness","aggregate.mutation.rate","load.data"), 
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
  save(fitness.data, file=paste0("msdb/fitness.data.", datetime.string(), ".RData"))

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
  load(paste0("msdb/",filename,".RData"))
  fitness.mean <- ddply(fitness.data, .(pop_size, beta, r, pi, tau, tick), summarize,
                        N = length(mean.fitness),
                        mean.fitness = mean(mean.fitness),
                        max.fitness = mean(max.fitness),
                        min.fitness = mean(min.fitness),
                        var.fitness = mean(var.fitness)
  )
  write.csv(fitness.mean, file=paste0("msdb/mean.",filename,".csv"))
  return(fitness.mean)
}

sge.aggregate.fitness()
                                                                                    