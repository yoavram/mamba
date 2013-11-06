library(ggplot2)
library(plyr)

setwd("D:/workspace/mamba/msdb")

df = read.csv("clicks.csv.gz")
names(df)

df = subset(df, beta==0.1)
df$tick1[is.na(df$tick1)] <- df$ticks[is.na(df$tick1)]

df$mutator = (df$pi > 0)*10 + (df$tau > 1)
df$mutator = factor(df$mutator, levels=c(0,1,11))#
df$mutator = factor(df$mutator, labels=c("NM","CM","SIM"))
colnames(df)[colnames(df)=='pop_size'] = 'N'

q = ggplot(df, aes(x=mutator,y=tick1)) + 
  facet_grid(facets=r~N, scales="free", labeller=function(var,val) { paste0(var,' = ',as.character(val)) }) +
  labs(x='Strategy', y='# Generations for First Click of the Ratchet')
  
q1 = q + geom_jitter(aes(color=mutator), alpha=I(0.5)) + 
  scale_color_manual(values=c('#377EB8','#E41A1C','#4DAF4A'), guide="none")  + 
  geom_boxplot(outlier.size=0,alpha=0) + 
  ylim(0,500) 
q1

ddf <- ddply(df, .(r,N,mutator), summarize,
             tick1.mean = mean(tick1),
             tick1.se = sd(tick1)/sqrt(length(tick1))             
             )

g = ggplot(ddf, aes(x=mutator,y=tick1.mean)) + 
  facet_grid(facets=r~N, scales="free_x", labeller=function(var,val) { paste0(var,' = ',as.character(val)) }) +
  labs(x='mutator', y='log mean time to first click')
g2 = g + geom_bar(aes(fill=mutator), stat="identity") + scale_y_log10() +
  scale_fill_manual(values=c('#377EB8','#E41A1C','#4DAF4A'), guide="none") +
  geom_errorbar(aes(ymax=tick1.mean+tick1.se, ymin=tick1.mean-tick1.se, position="dodge", width=0.2))


ggsave(filename="first.click_031113.png", plot=g2)