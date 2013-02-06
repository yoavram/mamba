source("common.R")

plot.mean.fitness <- function(jobname, filename, return.plot=T, save.to.file=T) {
  params <- load.params(jobname, filename)
  if (is.null(params)) {
    return(NULL)
  }
  if (params$in_rate == 0) {
    return(NULL)
  }
  data <- load.data(jobname, filename)
  if (is.null(data)) {
    return(NULL)
  } 
  title <- str_c(filename,"\n", "pop_size",params$pop_size,"s",params$s,"mu",params$mu,"r",params$r, "in_rate", params$in_rate, "in_tick", params$in_tick, "\n",
                 "resident:","pi",params$pi,"tau",params$tau,"phi",params$phi,"rho",params$rho, "\n",
                 "invader:","pi",params$in_pi,"tau",params$in_tau,"phi",params$in_phi,"rho",params$in_rho, sep=" " )
  
  df <- ddply(data, .(tick, fitness), summarize, 
              count = sum(population)
  )
  df2 <- ddply(df, .(tick), summarize, 
               mean.fitness = weighted.mean(fitness, count)
  )
  p <- qplot(x=tick, y=log(mean.fitness), data=df2, geom=c("point","line"))
  p <- p + ggtitle(title)
  p <- p + xlab('Generations') + ylab("Log Mean Fitness")
  p <- p + geom_hline(y=-as.numeric(as.character(params$mu)), colour="blue")
  
  if (save.to.file) {
    plot.filename <- str_c('output/', jobname, '/mean-fitness.', filename, ".png")
    dir.create(dirname(plot.filename), showWarnings = FALSE)
    ggsave(filename=plot.filename, plot=p)
  }
  
  if (return.plot){
    return(p)
  } else{
    return(NULL)
  }
}

plot.tau.frequency <- function(jobname, filename, return.plot=T, save.to.file=T) {
  params <- load.params(jobname, filename)
  if (is.null(params)) {
    return(NULL)
  }
  if (params$in_rate == 0) {
    return(NULL)
  }
  data <- load.data(jobname, filename)
  if (is.null(data)) {
    return(NULL)
  } 
  title <- str_c(filename,"\n", "pop_size",params$pop_size,"s",params$s,"mu",params$mu,"r",params$r, "in_rate", params$in_rate, "in_tick", params$in_tick, "\n",
                 "resident:","pi",params$pi,"tau",params$tau,"phi",params$phi,"rho",params$rho, "\n",
                 "invader:","pi",params$in_pi,"tau",params$in_tau,"phi",params$in_phi,"rho",params$in_rho, sep=" " )
  
  data$tau <- factor(data$tau)
  df <- ddply(data, .(tick, tau), summarize, 
              frequency = sum(population)
  )
  df$frequency <- df$frequency/params$pop_size
  
  p <- qplot(x=tick, y=frequency, data=df, geom="line", color=tau, group=tau)
  p <- p + ggtitle(title)
  p <- p + xlab('Generations') + ylab("Frequency")
  p <- p + geom_vline(x=as.numeric(as.character(params$in_tick)), colour="black", size=0.4)

  if (save.to.file) {
    plot.filename <- str_c('output/', jobname, '/tau-freq.', filename, ".png")
    dir.create(dirname(plot.filename), showWarnings = FALSE)
    ggsave(filename=plot.filename, plot=p)
  }
  if (return.plot){
    return(p)
  } else {
    return(NULL)
  }
}

process.one.jobname <- function(jobname) {
  files <- load.files.list(jobname)
  l1 <- lapply(files, plot.mean.fitness, jobname=jobname, return.plot=F, save.to.file=T)
  l2 <- lapply(files, plot.tau.frequency, jobname=jobname, return.plot=F, save.to.file=T)
  return(c(l1,l2))
}

process.all.files <- function() {
  jobnames <- load.jobnames.list()
  ret <- lapply(jobnames, process.one.jobname)
  return(ret)
}

process.one.file <- function(jobname, filename) {
  p1 <- plot.mean.fitness(jobname, filename, return.plot=F, save.to.file=T)
  p2 <- plot.tau.frequency(jobname, filename, return.plot=F, save.to.file=T)
  return(c(p1,p2))
}

## MAIN ##

args <- load.cmd.args()
if (length(args) == 0) {
  cat("Processing all output files\n")
  ret <- process.all.files()
  cat(ret)
} else if (length(argas) == 1) {
  jobname <- args[1]
  cat(str_c("Processing a single jobname: ", jobname, "\n"))
  ret <- process.one.jobname(jobname)
  cat(ret)  
} else {
  jobname <- args[1]
  filename <- args[2]
  cat(str_c("Processing a single file: ", jobname, filename, "\n"))
  ret <- process.one.file(jobname, filename)
  cat(ret)
}