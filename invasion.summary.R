source("common.R")

parse.invasion <- function(filename) {
  params <- load.params(filename)
  if (is.null(params) | params$in_rate == 0) {
    return(NULL)
  }
  data <- load.data(filename)
  if (is.null(data)) {
    return(NULL)
  } 
  data <- subset(data, tick==max(data$tick))
  stopifnot(length(unique(data$tick))==1)
  df <- ddply(data, .(tick, tau, pi, rho, phi), summarize, 
              frequency = sum(population)/params$pop_size
  )
  df <- cbind(df, sumatra_label=filename)
  df <- merge(x=df, y=params, by="sumatra_label", suffixes=c(".data",""))
  return(df)
}

invasion.summary <- function(data) {
  df <- subset(data, pi.data == in_pi & tau.data == in_tau & phi.data == in_phi & rho.data == in_rho)
  df.summary <- ddply(df, .(pi,tau,phi,rho,in_pi,in_tau,in_phi,in_rho,in_rate,mu,s,r,rb,pop_size,num_loci,in_tick,envch_str,envch_start,envch_rate,ticks), summarize,
              num.simulations = length(frequency),
              mean.frequency = mean(frequency),
              sd.frequency = sd(frequency),            
              sucesses = sum(frequency > in_rate)
  )
  df.summary <- ddply(df.summary, .(pi,tau,phi,rho,in_pi,in_tau,in_phi,in_rho,in_rate,mu,s,r,rb,pop_size,num_loci,in_tick,envch_str,envch_start,envch_rate,ticks), transform,
              se.frequency = sd.frequency/sqrt(num.simulations),
              fixation.probability = sucesses/num.simulations,
              p.value = binom.test(x=sucesses, n=num.simulations, p=unique(in_rate))$p.value
  )
  return(df.summary)
}

files <- load.files.list()
df <- adply(files, 1, parse.invasion)
df <- invasion.summary(df)
df$envch_rate<-factor(df$envch_rate)
qplot(x=envch_rate,y=num.simulations,data=df,facets=in_pi~in_tau,geom="bar",stat="identity")
qplot(x=envch_rate,y=mean.frequency,data=df,facets=in_pi~in_tau,geom="bar",stat="identity")