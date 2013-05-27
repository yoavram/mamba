library(ggplot2)
library(plyr)

fname <- "output/invasion_26_05_2013"
df <- read.csv(paste0(fname,".csv.gz"))
df <- df[df$r < 0.3,]
df$in_tau <- factor(df$in_tau)
df$in_tau <- factor(df$in_rho)
df$r <- factor(df$r)
df$in_phi[df$in_phi==1000] <- 'NR'
df$in_phi[df$in_phi==1] <- 'SIR'
df$in_phi[df$in_phi==0] <- 'CR'
df$in_pi[df$in_pi==1000] <- 'NM'
df$in_pi[df$in_pi==1] <- 'SIM'
df$in_pi[df$in_pi==0] <- 'CM'

summary(df$final_tick)
qplot(df$final_tick)
qplot(df$in_final_rate)

q=ggplot(df, aes(x=r,y=final_tick,color=in_pi,group=in_pi))
q1=q+geom_jitter(alpha=1)+facet_grid(in_rho~in_phi)
q2=q1+scale_fill_brewer(palette="Set1", name="invader")

time.df <- ddply(df, .(in_phi,in_pi,in_tau,in_rho,r), summarize,
                 N = length(in_final_rate),
                 mean.tick = mean(final_tick, na.rm=T),
                 se.tick = sd(final_tick, na.rm=T)/sqrt(length(final_tick)))

q=ggplot(time.df, aes(x=r,y=mean.tick,group=in_pi))
q1=q + geom_bar(aes(fill=in_pi), stat="identity", position=dodge, width=0.9)
q2=q1+facet_grid(in_rho~in_phi)
q3=q2+scale_fill_brewer(palette="Set1", name="invader")
q3+scale_alpha_manual(values=c(0,1))

ggsave(plot=q3, filename=paste0(fname,'_time.pdf'), width=11,heigh=8)

agg.df.all <- ddply(df, .(beta, mu, in_phi,in_pi,in_tau,in_rho,r, envch_str), summarize,
                N = length(in_final_rate),
                mean.tick = mean(final_tick, na.rm=T),
                se.tick = sd(final_tick, na.rm=T)/sqrt(length(final_tick)),
                mean.invasion = mean(in_final_rate,na.rm=T),                
                se.invasion = sd(in_final_rate,na.rm=T)/sqrt(length(in_final_rate)))

agg.df <- subset(agg.df.all, beta < 1 & mu == 0.003 & envch_str == 4 & in_tau != 20 & in_tau != 1)# & in_tau!=20)

q=ggplot(agg.df,aes(x=r,y=N, group=in_pi))
q2=q+facet_grid(facets=in_rho~in_phi)
q3=q2+geom_bar(aes(fill=in_pi), stat="identity", position="dodge")
q3

dodge <- position_dodge(width=0.9)

# GENERAL INVASION SUCCESS PLOT
q=ggplot(agg.df, aes(x=r,y=mean.invasion-0.5, group=in_pi, ymin=mean.invasion-0.5-2*se.invasion,ymax=mean.invasion-0.5+2*se.invasion))
q2=q + facet_grid(facets=in_rho~in_phi)#, labeller=function(var,val) {if (var=='in_rho') return(paste0('X',val)) else return(val)})
q3=q2 + geom_bar(aes(fill=in_pi), stat="identity", position=dodge, width=0.9)
q4=q3 + coord_cartesian(ylim=c(0-0.25,1-0.6))
q5=q4+geom_errorbar(position=dodge, width=0.3)
q6=q5+scale_y_continuous(breaks=c(-0.5,-0.25,0,0.25,0.5), labels=c(0,0.25,0.5,0.75,1))
q7=q6+labs(x="recombination rate", y="mean invasion success")
q8=q7+scale_fill_brewer(palette="Set1", name="invader")
q8

ggsave(filename=paste0(fname,'.pdf'), plot=q8, height=8.27, width=11.69)
write.csv(agg.df, file=paste0(fname, '.csv'))

# SIM ADVANTAGE WITH RECOMBINATION
q=ggplot(subset(agg.df, in_phi=='NR' & as.numeric(in_tau) <= 10), aes(x=r,y=mean.invasion-0.5, group=in_pi, ymin=mean.invasion-0.5-2*se.invasion,ymax=mean.invasion-0.5+2*se.invasion))
q2=q + facet_grid(facets=in_tau~.)#, labeller=function(var,val) {return(paste0('X',val))})
q3=q2 + geom_bar(aes(fill=in_pi), stat="identity", position=dodge, width=0.9)
q4=q3 + coord_cartesian(ylim=c(0-0.25,1-0.6))
q5=q4 + geom_errorbar(position=dodge, width=0.3)
q6=q5 + scale_y_continuous(breaks=c(-0.5,-0.25,0,0.25,0.5), labels=c(0,0.25,0.5,0.75,1))
q7=q6 + labs(x="recombination rate", y="mean invasion success")
q8=q7 + scale_fill_brewer(palette="Set1", name="invader")
q8

ggsave(filename=paste0(fname,'_SIM_with_r.pdf'), plot=q8, width=8.27, height=11.69)

# beta=1
agg.df.beta1 <- subset(agg.df.all, beta == 1 & in_tau != 1)
unique(agg.df.beta1$beta)
unique(agg.df.beta1$in_tau)
unique(agg.df.beta1$r)
unique(agg.df.beta1$mu)

# GENERAL INVASION SUCCESS PLOT
q=ggplot(agg.df.beta1, aes(x=r,y=mean.invasion-0.5, group=in_pi, ymin=mean.invasion-0.5-2*se.invasion,ymax=mean.invasion-0.5+2*se.invasion))
q2=q + facet_grid(facets=in_rho~in_phi)
q3=q2 + geom_bar(aes(fill=in_pi), stat="identity", position=dodge, width=0.9)
q4=q3 + coord_cartesian(ylim=c(0-0.25,1-0.5))
q5=q4+geom_errorbar(position=dodge, width=0.3)
q6=q5+scale_y_continuous(breaks=c(-0.5,-0.25,0,0.25,0.5), labels=c(0,0.25,0.5,0.75,1))
q7=q6+labs(x="recombination rate", y="mean invasion success")
q8=q7+scale_fill_brewer(palette="Set1", name="invader")
q8

ggsave(filename=paste0(fname,'_beta_1.pdf'), plot=q8, height=8.27, width=11.69)


# SPECIFIC COMPARISON FOR LILACH'S TALK

df.lilach <- subset(agg.df, (in_tau==5 | in_tau==10) & envch_str==4)
df.lilach <- subset(agg.df, (in_pi=='SIM' & in_phi=='NR') | (in_pi=='SIM' & in_phi=='SIR') | (in_pi=='NM' & in_phi=='SIR'))
df.lilach$invader <- factor(paste(df.lilach$in_pi, df.lilach$in_phi))

q = ggplot(df.lilach, aes(x=invader, y=mean.invasion-0.5, group=in_pi, ymin=mean.invasion-0.5-2*se.invasion,ymax=mean.invasion-0.5+2*se.invasion))
q2 = q + facet_grid(facets=in_tau~r)
q3 = q2 + geom_bar(aes(fill=invader), stat="identity", position=dodge, width=0.9)
q4=q3 + coord_cartesian(ylim=c(0-0.25,1-0.5))
q5=q4+geom_errorbar(position=dodge, width=0.3)
q6=q5+scale_y_continuous(breaks=c(-0.5,-0.25,0,0.25,0.5), labels=c(0,0.25,0.5,0.75,1))
q7=q6+labs(y="mean invasion success")
q8=q7+scale_fill_brewer(palette="Set1")
q8

ggsave(filename=paste0(fname, "_sim_sir.pdf"), plot=q8, height=8.27, width=11.69)