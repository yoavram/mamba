library(ggplot2)
library(plyr)
library(rjson)
setwd("~/lecs/workspace/mamba/simarba")

today = Sys.Date()

filenames = list.files("../output/adaptation/", pattern="*.json", full.names=TRUE)

df = ldply(filenames, function(x) {as.data.frame(fromJSON(file=x))})
write.csv(df, file=paste0("adaptation_summary_",today,".csv"))

df = read.csv("adaptation_summary_111113.csv")

ddf = subset(df, tau>1)
ddf = ddply(ddf, .(beta,phi,s,pi,pop_size,r,envch_str,mu,rho,tau), 
            function(x) mean_se(x$final_tick)     
)

ddf$pi = factor(ddf$pi,levels=c(0,1000,1),labels=c("CM","NM","SIM"))
ddf$r = factor(ddf$r)

g = ggplot(data=ddf,mapping=aes(x=r,y=y)) + 
  facet_grid(facets=pop_size+envch_str~tau, scales="free") + 
  labs(y="log adaptation time", x="recombination rate") +
  scale_y_log10()
g1 = g + geom_line(aes(color=pi,group=pi))  + scale_color_brewer("mutator", palette="Set1")
g2 = g1 + geom_errorbar(aes(ymax=ymax, ymin=ymin), width=0.2)
g2 

ggsave(plot=g2,filename=paste0("adaptation_",today,".png"),width = 210, height = 297, units = "mm")
#ggsave(plot=g2,filename=paste0("adaptation_pop_",unique(ddf$pop_size),'_envch_str_',unique(ddf$envch_str),"_",today,".png"))
