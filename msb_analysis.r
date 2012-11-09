library(ggplot2)
library(plyr)
library(RColorBrewer)

crunch.data <- function(fname, s=0.01, mu=0.003) {
  df <- read.csv(fname, header=T)
  
  # sf = summarized df
  
  # got to calc the observed mean of mutation load before i can calc the expected
  # because it is the parameter for the poisson dist.
  sf <- ddply(df, .(tick), transform,
              obs.mean = weighted.mean(mutation.load, population),
              max.load = max(mutation.load))
  
  # sum counts of different types with the same load, and calc theoretical msb loads
  sf <- ddply(sf, .(tick, mutation.load), summarize, 
              observed = sum(population),
              theoretical = dpois(x=unique(mutation.load), lambda=(mu.rate/s)*(1-(1-s)^unique(tick)))*pop.size,
              obs.mean=unique(obs.mean))
  
  sf <- ddply(sf, .(tick, mutation.load), transform, 
              expected = dpois(x=unique(mutation.load), lambda=unique(obs.mean))*pop.size            
  
  return(sf)
}

plot.summary <- function(sf) {
  pal <- rev(brewer.pal(3,"Set1"))
  p <- ggplot(data=sf, mapping=aes(mutation.load))
  
  q <- p + ggtitle(label="Mutation load distribution") + 
    geom_point(mapping=aes(y=expected, colour="expected")) +
    geom_point(mapping=aes(y=observed, colour="observed")) +
    geom_line(mapping=aes(y=theoretical, colour="theoretical"), linetype=2) +
    facet_grid(tick~.) +
    geom_vline(aes(xintercept=obs.mean), colour=pal[2]) + 
    geom_vline(aes(xintercept=mu.rate/s), colour=pal[3]) +
    
    xlab(label="# of deleterious mutations") +
    ylab(label="# of individuals") + 
    scale_colour_manual(values = pal, name="") 
  
  return(q)
}

test.goodnes.of.fit <- function(observed, expected, reduction.df) {
  # http://en.wikipedia.org/wiki/Pearson%27s_chi-squared_test
  chisquare.statistic <- sum( (observed-expected)^2/ expected)
  df <- length(expected)-1-reduction.df
  if (df<=1) {
    return(NA)
  }
  pval <- pchisq(q=chisquare.statistic, df=df)
  return(pval)  
}

source("params.r")
file.list <- list.files(path='output/',pattern="msb_\\w*.csv",full.names=T)
for (fname in file.list) {
  sf <- crunch.data(fname=fname)
  p <- plot.summary(sf=sf)
  png.name <- gsub(x=fname, pattern=".csv",replacement=".png")
  if (interactive() ) print(p) 
  ggsave(filename=png.name, plot=p)
  ssf <- subset(sf, tick==max(tick))
  pval1 <- test.goodnes.of.fit(ssf$observed/pop.size, ssf$expected/pop.size, 1) # 1 for poisson parameter
  pval2 <- test.goodnes.of.fit(ssf$observed/pop.size, ssf$theoretical/pop.size, 1) # 1 for poisson parameter
  print(paste("fname: ",fname,"pvalues: ",pval1,pval2))
}