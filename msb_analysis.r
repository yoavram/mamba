library(ggplot2)
library(plyr)
library(RColorBrewer)

crunch.data <- function(fname, s=0.01, mu=0.003) {
  df<-read.csv(fname, header=T)
  
  # sf = summarized df
  sf<-ddply(df,.(mutation.load), summarize, count=sum(count))
  
  obs.mean <- weighted.mean(sf$mutation.load, sf$count)
  expect <- dpois(0:max(sf$mutation.load), lambda=obs.mean)
  expect <- expect*sum(df$count)
  
  theor <- dpois(0:max(sf$mutation.load), lambda=mu/s)
  theor <- theor*sum(df$count)
  
  sf <- cbind(sf, theor, expect)
  
  return(sf)
}

plot.summary <- function(sf) {
  obs.mean <- weighted.mean(sf$mutation.load, sf$count)
  
  p <- ggplot(data=sf, mapping=aes(mutation.load))
  
  q <- p + ggtitle(label="Mutation load distribution") + 
    
    geom_point(mapping=aes(y=count, colour="observed")) +
    geom_point(mapping=aes(y=expect, colour="expected")) +
    geom_line(mapping=aes(y=theor, colour="theoretical"), linetype=2) +
    
    xlab(label="# of deleterious mutations") +
    ylab(label="# of individuals") + 
    scale_colour_manual(values = rev(brewer.pal(3,"Set1")), name="") +
    geom_vline(xintercept=c(mu/s, obs.mean)) 
  
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

file.list <- list.files(path='output/',pattern="mamba_\\w*.csv",full.names=T)
for (fname in file.list) {
  sf <- crunch.data(fname=fname)
  p <- plot.summary(sf=sf)
  png.name <- gsub(x=fname, pattern=".csv",replacement=".png")
  if (interactive() ) print(p) 
  ggsave(filename=png.name, plot=p)
  print(paste("fname: ",fname,"pvalue: ",test.goodnesoffit.poisson(sf=sf)))
}