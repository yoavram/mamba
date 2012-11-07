library(ggplot2)
library(plyr)
library(RColorBrewer)

crunch.data <- function(fname, s=0.01, mu=0.003) {
  df <- read.csv(fname, header=T)
  
  # sf = summarized df
  
  # sum counts of different types with the same load, and calc theoretical msb loads
  sf <- ddply(df, .(tick, mutation.load), transform, 
    observed = sum(population),
    theoretical = dpois(x=unique(mutation.load), lambda=(mu.rate/s)*(1-(1-s)^unique(tick)))*pop.size)
  
  # got to calc the observed mean of mutation load before i can calc the expected
  # because it is the parameter for the poisson dist.
  sf <- ddply(sf, .(tick), transform,
    obs.mean = weighted.mean(mutation.load, population),
    max.load = max(mutation.load))
  
  sf <- ddply(sf, .(tick, mutation.load), transform, 
    expected = dpois(x=unique(mutation.load), lambda=unique(obs.mean))*pop.size)
  
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

test.goodnesoffit.poisson <- function(sf) {
  # I DONT THINK THIS WORKS
  # http://www.zoology.ubc.ca/~whitlock/bio300/lecturenotes/gof/gof.html
  sf <- subset(sf, tick==max(tick))
  chisquare.statistic <- sum(((sf$count-sf$expect)/sf$expect)^2)
  df <- length(sf$count)-2 # one parameter for the poisson distribution
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
  sf <- subset(sf, tick %in% c(0,100,500,1000) )
  p <- plot.summary(sf=sf)
  png.name <- gsub(x=fname, pattern=".csv",replacement=".png")
  if (interactive() ) print(p) 
  ggsave(filename=png.name, plot=p)
  print(paste("fname: ",fname,"pvalue: ",test.goodnesoffit.poisson(sf=sf)))
}