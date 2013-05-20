library(ggplot2)
library(plyr)

fname <- "output/invasion_20_05_2013"
df <- read.csv(paste0(fname,".csv.gz"))
df <- df[df$r < 0.3,]
df$in_tau <- factor(df$in_tau)
df$in_pi <- factor(df$in_pi)
df$r <- factor(df$r)
df$in_phi[df$in_phi==1000] <- 'NR'
df$in_phi[df$in_phi==1] <- 'SIR'
df$in_phi[df$in_phi==0] <- 'CR'

summary(df$final_tick)
qplot(df$final_tick)
qplot(df$in_final_rate)

q=ggplot(df,aes(x=r,y=final_tick,color=in_pi,group=in_pi))
q1=q+geom_jitter()+facet_grid(in_rho~in_phi)
q1

agg.df <- ddply(df, .(in_phi,in_pi,in_tau,in_rho,r), summarize,
                N = length(in_final_rate),
                mean.tick = mean(final_tick, na.rm=T),
                se.tick = sd(final_tick, na.rm=T)/sqrt(length(final_tick)),
                mean.invasion = mean(in_final_rate,na.rm=T),                
                se.invasion = sd(in_final_rate,na.rm=T)/sqrt(length(in_final_rate)))

q=ggplot(agg.df,aes(x=r,y=N, group=in_pi))
q2=q+facet_grid(facets=in_rho~in_phi)
q3=q2+geom_bar(aes(fill=in_pi), stat="identity", position="dodge")
q3

dodge <- position_dodge(width=0.9)

# GENERAL INVASION SUCCESS PLOT
q=ggplot(agg.df, aes(x=r,y=mean.invasion-0.5, group=in_pi, ymin=mean.invasion-0.5-2*se.invasion,ymax=mean.invasion-0.5+2*se.invasion))
q2=q + facet_grid(facets=in_rho~in_phi)
q3=q2 + geom_bar(aes(fill=in_pi), stat="identity", position=dodge, width=0.9)
q4=q3 + coord_cartesian(ylim=c(0-0.5,1-0.5))
q5=q4+geom_errorbar(position=dodge, width=0.3)
q6=q5+scale_y_continuous(breaks=c(-0.5,-0.25,0,0.25,0.5), labels=c(0,0.25,0.5,0.75,1))
q7=q6+labs(x="recombination rate", y="mean invasion success")
q8=q7+scale_fill_brewer(palette="Set1", name="invader", labels=c("CM","SIM","NM"))
q8
ggsave(filename=paste0(fname,'.pdf'), plot=q8, height=8.27, width=11.69)

# GENERAL INVASION TIME PLOT
q=ggplot(agg.df, aes(x=r,y=mean.tick, group=in_pi, ymin=mean.tick-2*se.tick, ymax=mean.tick+2*se.tick))
q2=q + facet_grid(facets=in_rho~in_phi)
q3=q2 + geom_bar(aes(fill=in_pi), stat="identity", position=dodge, width=0.9)
q4=q3# + coord_cartesian(ylim=c(0-0.5,1-0.5))
q5=q4+geom_errorbar(position=dodge, width=0.3)
q6=q5#+scale_y_continuous(breaks=c(-0.5,-0.25,0,0.25,0.5), labels=c(0,0.25,0.5,0.75,1))
q7=q6+labs(x="recombination rate", y="mean invasion time")
q8=q7+scale_fill_brewer(palette="Set1", name="invader", labels=c("CM","SIM","NM"))
q8

ggsave(filename=paste0(fname,'_time.pdf'), plot=q8, height=8.27, width=11.69)


# SIM ADVANTAGE WITH RECOMBINATION
q=ggplot(subset(agg.df, in_phi=='SIR' & as.numeric(in_tau) <= 10), aes(x=r,y=mean.invasion-0.5, group=in_pi, ymin=mean.invasion-0.5-2*se.invasion,ymax=mean.invasion-0.5+2*se.invasion))
q2=q + facet_grid(facets=in_tau~., labeller=function(var,val) {return(paste0('X',val))})
q3=q2 + geom_bar(aes(fill=in_pi), stat="identity", position=dodge, width=0.9)
q4=q3 + coord_cartesian(ylim=c(0-0.5,1-0.5))
q5=q4 + geom_errorbar(position=dodge, width=0.3)
q6=q5 + scale_y_continuous(breaks=c(-0.5,-0.25,0,0.25,0.5), labels=c(0,0.25,0.5,0.75,1))
q7=q6 + labs(x="recombination rate", y="mean invasion success")
q8=q7 + scale_fill_brewer(palette="Set1", name="invader", labels=c("CM","SIM","NM"))
q8
ggsave(filename=paste0(fname,'_SIM_with_r.pdf'), plot=q8, width=8.27, height=11.69)


