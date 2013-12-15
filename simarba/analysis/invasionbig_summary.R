library(ggplot2)
library(plyr)
library(rjson)

today = Sys.Date()

setwd("~/lecs/workspace/mamba/simarba")
          
df1 = read.csv(file="invasion_summary_2013-11-17.csv")
df2 = read.csv(file="invasionbig_summary_2013-11-17.csv")
df2 = subset(df2, select=-c(adapt))
df3 = read.csv(file="invasion_rb_summary_2013-11-19.csv")
df3 = subset(df3, select=-c(adapt))

df = rbind(df1, df2, df3)

ddf = ddply(df, .(in_phi, beta,in_tau,phi,s,in_tick,pi,pop_size,envch_rate,in_pi,r,envch_start,in_rate,rb,envch_str,in_rho,mu,rho,tau), 
            function(x) mean_se(x$in_final_rate)            
)
ddf$in_pi = factor(ddf$in_pi,levels=c(0,1000,1),labels=c("CM","NM","SIM"))
ddf$r = factor(ddf$r)

ddf = subset(ddf, in_phi==1000 & beta<1 & rb==F & pop_size<1e8 & s==0.1)

g = ggplot(data=ddf,mapping=aes(x=r,y=y)) + facet_grid(facets=pop_size+envch_str~in_tau) + 
  labs(y="invader rate", x="recombination rate")
g1 = g + geom_line(aes(color=in_pi,group=in_pi))  
g2 = g1  + geom_errorbar(aes(ymax=ymax,ymin=ymin), position="dodge", width=0.2) + theme(axis.text.x = element_text(angle = 270, hjust = 1))
g2

ggsave(filename=paste0("invasion_",today,".png"), plot=g2)
