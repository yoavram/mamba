library(ggplot2)
library(plyr)


df <- read.csv("output/invasion_18_05_2013.csv.gz")
df$in_tau <- factor(df$in_tau)
df$in_pi <- factor(df$in_pi)
df$r <- factor(df$r)

summary(df$final_tick)
qplot(df$final_tick)
qplot(df$in_final_rate)

q=ggplot(df,aes(x=r,y=in_final_rate,color=in_pi,group=in_pi))
q1=q+geom_jitter()+facet_grid(in_rho~in_phi)
q1

agg.df <- ddply(df, .(in_phi,in_pi,in_tau,in_rho,r), summarize,
                N = length(in_final_rate),
                mean.tick = mean(final_tick, na.rm=T),
                mean.invasion = mean(in_final_rate,na.rm=T),
                sd.invasion = sd(in_final_rate,na.rm=T),
                se.invasion = sd(in_final_rate,na.rm=T)/sqrt(length(in_final_rate)))

q=ggplot(agg.df,aes(x=r,y=N, group=in_pi))
q2=q+facet_grid(facets=in_rho~in_phi)
q3=q2+geom_bar(aes(fill=in_pi), stat="identity", position="dodge")
q3

dodge <- position_dodge(width=0.9)
q=ggplot(agg.df,aes(x=r,y=mean.invasion-0.5, group=in_pi, ymin=mean.invasion-0.5-se.invasion,ymax=mean.invasion-0.5+se.invasion))
q2=q + facet_grid(facets=in_rho~in_phi)
q3=q2 + geom_bar(aes(fill=in_pi), stat="identity", position=dodge, width=0.9)
q4=q3 + coord_cartesian(ylim=c(0-0.5,1-0.5))
q5=q4+geom_errorbar(position=dodge, width=0.3)
q6=q5+scale_y_continuous(breaks=c(-0.5,-0.25,0,0.25,0.5), labels=c(0,0.25,0.5,0.75,1))
q7=q6+labs(x="recombination rate", y="mean invasion sucess")
q8=q7+scale_fill_brewer(palette="Set1", name="invader", labels=c("CM","SIM","NM"))
q8