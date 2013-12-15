library(ggplot2)
library(plyr)
library(rjson)

today = Sys.Date()

setwd("~/lecs/workspace/mamba/simarba")

df0 = read.csv(file="adaptation2_XXXXX.csv")
df = subset(df0, pop_size==1e6 & envch_str==4 & tau==5 & phi==1000 & rb==F & beta<1 & s==0.1)
df$pi = factor(df$pi,levels=c(0,1000,1),labels=c("CM","NM","SIM"))
df$r = factor(df$r)

df = subset(df, r==0 | r==0.03)

output = NULL
for (i in seq(dim(df)[1])) {
  filename = df$sumatra_label[i]
  path = paste0("../output/adaptation/",filename,".csv.gz")
  data = read.csv(path)
  fitness = ddply(data, .(tick), summarize,
                  max.fitness = max(fitness),
                  min.fitness = min(fitness),
                  mean.fitness = weighted.mean(fitness, population)
                  
  )
  fitness = cbind(fitness, r=df$r[i], pi=df$pi[i], tau=df$tau[i], filename=filename)
  output = rbind(output, fitness)
}
write.csv(output, file=paste0("mean_fitness_",today,".csv"))


fitness = ddply(output, .(tick, pi, tau, r), summarize,
                #max.fitness = max(fitness),
                #min.fitness = min(fitness),
                mean.fitness = mean(mean.fitness)
                #sd.fitness = sd(fitness)
)

qplot(x=tick,y=mean.fitness,data=fitness, geom=c("point","line"), color=pi) + 
  facet_grid(facets=r~pi, scales="free_x") + scale_color_brewer("invader", palette="Set1")

