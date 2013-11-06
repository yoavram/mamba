library(ggplot2)
library(plyr)
library(rjson)
setwd("~/lecs/workspace/mamba/simarba")

filenames = list.files("../output/invasionbig/", pattern="*.json", full.names=TRUE)

df = ldply(filenames, function(x) {as.data.frame(fromJSON(file=x))})
write.csv(df, file="invasionbig_summary_031113.csv")

df = read.csv(file="invasionbig_summary_031113.csv")

ddf = subset(df, in_phi==1000)
ddf = ddply(ddf, .(beta,in_tau,phi,s,in_tick,pi,pop_size,envch_rate,in_pi,r,envch_start,in_rate,rb,envch_str,in_rho,mu,rho,tau), 
            function(x) mean_se(x$in_final_rate)     
            )
ddf$in_pi = factor(ddf$in_pi,levels=c(0,1000,1))#,labels=c("CM","NM","SIM"))
ddf$r = factor(ddf$r)

g = ggplot(data=ddf,mapping=aes(x=r,y=y-0.5)) + 
  facet_grid(facets=.~in_tau) + 
  labs(y="invader rate", x="recombination rate", title=paste0("pop size ",unique(ddf$pop_size))) + 
  scale_y_continuous(lim=c(-0.5,0.3),breaks=c(-0.5,-0.25,0,0.25,0.5), labels=c(0,0.25,0.5,0.75,1))
g1 = g + geom_line(aes(color=in_pi, group=in_pi), )  + scale_color_brewer("invader", palette="Set1")
g2 = g1 + geom_errorbar(aes(ymax=ymax-0.5, ymin=ymin-0.5), width=0.2)
g2 

ggsave(filename="invasionbig_summary_031113.png", plot=g2)

ddf = read.csv("invasion_26_05_2013.csv")
names(ddf)
ddf = subset(ddf, in_phi=='NR' & mu==0.003 & beta==0.1 & envch_str==4)
ddf$r = factor(ddf$r)
dim(ddf)

g = ggplot(data=ddf,mapping=aes(x=r,y=mean.invasion-0.5)) + 
  facet_grid(facets=.~in_tau) + 
  labs(y="invader rate", x="recombination rate", title=paste0("pop size ",unique(ddf$pop_size))) + 
  scale_y_continuous(lim=c(-0.5,0.3),breaks=c(-0.5,-0.25,0,0.25,0.5), labels=c(0,0.25,0.5,0.75,1))
g1 = g + geom_line(aes(color=in_pi, group=in_pi), )  + scale_color_brewer("invader", palette="Set1")
g2 = g1 + geom_errorbar(aes(ymax=mean.invasion-0.5-se.invasion, ymin=mean.invasion-0.5+se.invasion), width=0.2)
g2 

ggsave(filename="invasion_summary_031113.png", plot=g2)
