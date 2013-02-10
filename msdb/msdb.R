source("common.R")

first.ratchet.click <- function(jobname, filename) {
  data <- load.data(jobname, filename)
  
  df <- ddply(data, .(tick), summarize, min.fitness=min(fitness), max.fitness=max(fitness))
  first.click <- min(which(df$max.fitness<1))
  if (is.infinite(first.click)){
    first.click = max(df$tick)
  } else {
    first.click <- df$tick[first.click]
  }
  return(first.click)
}

jobname <- "msdb"
files <- load.files.list(jobname)

data <- NULL
for (filename in files) {
  params <- data.frame(load.params(jobname, filename))
  data <- rbind(data, params)
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

df <- ddply(data, .(sumatra_label), transform, first.click=first.ratchet.click(jobname, sumatra_label))
save(df, file="msdb/no_beneficials.RData")

r0 <- plot.first.click.distr(subset(df,pop_size!=5000 & r==0), "r=0")
r0.003 <- plot.first.click.distr(subset(df,pop_size!=5000 & r==0.003), "r=0.003")

pdf("msdb/no_beneficials.pdf",paper="a4")
grid.arrange(r0,r0.003, ncol=1)
dev.off()