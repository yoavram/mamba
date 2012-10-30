library(ggplot2)
library(plyr)
library(RColorBrewer)

crunch.data <- function(fname, s=0.01, mu=0.003) {
  df <- read.csv(fname, header=T)
  
  # sf = summarized df
  sf <- ddply(df, .(tick, mutation.load), transform, 
    count = sum(count),
    theoretical = dpois(x=unique(mutation.load), lambda=mu.rates/s)*pop.size)
    
  sf <- ddply(sf, .(tick), transform,
    #count = sum(count),
    obs.mean = weighted.mean(mutation.load, count),
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
    geom_point(mapping=aes(y=count, colour="observed")) +
    geom_line(mapping=aes(y=theoretical, colour="theoretical"), linetype=2) +
    facet_grid(.~tick) +
    geom_vline(aes(xintercept=obs.mean), colour=pal[2]) + 
    geom_vline(aes(xintercept=mu.rate/s), colour=pal[3]) +
    
    xlab(label="# of deleterious mutations") +
    ylab(label="# of individuals") + 
    scale_colour_manual(values = pal, name="") 
  
  return(q)
}

test.goodnesoffit.poisson <- function(sf) {
  # http://www.zoology.ubc.ca/~whitlock/bio300/lecturenotes/gof/gof.html
  chisquare.statistic <- sum((sf$count-sf$expect)^2/sf$expect)
  df <- length(sf$count)-2 # one parameter for the poisson distribution
  if (df<=1) {
    return(NA)
  }
  pval <- pchisq(q=chisquare.statistic, df=df)
  return(pval)  
}

mu <- 0.003
s <- 0.01

file.list <- list.files(path='output/',pattern="msb_\\w*.csv",full.names=T)
for (fname in file.list) {
  sf <- crunch.data(fname=fname)
  p <- plot.summary(sf=sf)
  png.name <- gsub(x=fname, pattern=".csv",replacement=".png")
  if (interactive() ) print(p) 
  ggsave(filename=png.name, plot=p)
  print(paste("fname: ",fname,"pvalue: ",test.goodnesoffit.poisson(sf=sf)))
}