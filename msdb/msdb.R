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

df <- ddply(data, .(sumatra_label), transform, first.click=first.ratchet.click(jobname, sumatra_label))
save(df, "msdb/dataframe.RData")
p <- ggplot(df, aes(x=first.click, fill=pi+tau))
p <- p + stat_bin() + facet_grid(facets=tau+r~pop_size, scales="free_y") + scale_fill_continuous()
ggsave("msdb/histogram.pdf")

