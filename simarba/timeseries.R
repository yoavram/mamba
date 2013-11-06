library(ggplot2)
library(plyr)
setwd("~/lecs/workspace/mamba/simarba")

df = read.csv("../output/invasionbig/2013-Oct-29_14-27-51-331793.csv.gz")
fitness = ddply(df, .(tick), summarize,
           max.fitness = max(fitness),
           min.fitness = min(fitness),
           mean.fitness = mean(fitness),
           sd.fitness = sd(fitness)
           )
qplot(x=tick,y=max.fitness, data=fitness, geom="line")

invader = ddply(df, .(tick), summarize,
           fraction  = mean(tau>1)        
           )
qplot(x=tick,y=invader, data=fraction, geom="line")