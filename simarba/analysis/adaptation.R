library(plyr)
library(ggplot2)
library(reshape2)
library(gridExtra)
library(data.table)

today = Sys.Date()

dt = fread("../adaptation_summary_2014-03-23.csv")
dt$real.tau = dt$tau
dt[pi==1000]$real.tau = 1

dtt = dt[, mean_se(final_tick), by="s,beta,pi,tau,r,phi,rho,pop_size,envch_str,mu,num_loci,real.tau"]

dtt[,pi:=factor(dtt$pi,levels=c(0,1,1000),labels=c("CM","SIM","NM"))]
dtt[,phi:=factor(dtt$phi,levels=c(0,1,1000),labels=c("CR","SIR","NR"))]

## analytic approximation
dtt[, q:= exp(-real.tau*mu/s) * (beta/2) * real.tau*mu * exp(-real.tau*mu) / num_loci]
dtt[, fp:= (1-exp(-2*s))/(1-exp(-2*pop_size*s))]
dtt[, approx:=1/(pop_size*fp*q)]

qplot(y=y,x=approx,data=subset(dtt,envch_str==1), color=r) + 
  geom_abline(intercept=0, slope=1)

# factors
dtt[,pop_size:=as.factor(pop_size)]
dtt[,r:=as.factor(r)]
dtt[,tau:=as.factor(tau)]
dtt[,rho:=as.factor(rho)]
dtt[,pop_size:=as.factor(pop_size)]
dtt[,envch_str:=as.factor(envch_str)]

# Overview
data = dtt[phi=="NR"]# & pi!="NM"]
g = ggplot(data=data,
           mapping=aes(x=r, y=y, color=pi, group=interaction(pi,envch_str))) +
  theme_bw() + 
  geom_line(aes(linetype=pi), size=1) +   
  geom_errorbar(aes(y=y,ymax=ymax, ymin=ymin, color=pi), width=0.1) + 
  geom_point(aes(shape=envch_str), size=3) + 
  facet_grid(facets=envch_str+pop_size~tau, scales="free", labeller=tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(y="Adaptation time\n", x="Recombination rate")
g = g + scale_color_brewer("Mutator", palette="Set1") +
  #  scale_y_log10(breaks=c(100,250,500,1000,2000,5000)) +
  scale_linetype_manual("Mutator", values=c("dashed","solid","dotted")) +
  scale_shape_manual("# Mutaions", values=c(16,2))
g

ggsave(filename=paste0("adaptation_NR_",today,".png"), plot=g, width=7, height=6)

g$data <- subset(g$data, tau==10 & changes==1)
g = g + facet_grid(pop_size~envch_str, scales="free", labeller=tau_label)
g + geom_point(y=approx)

ggsave(filename=paste0("adaptation_NR_tau_10_",today,".png"), plot=g, width=7, height=6)

# mutational supply
data = dtt[phi=="NR"]
g = ggplot(data=data,
           mapping=aes(x=mu.supp, y=y, color=pi, group=interaction(pi,envch_str))) +
  theme_bw() + 
  #geom_line(aes(linetype=pi), size=1) +   
  geom_errorbar(aes(y=y,ymax=ymax, ymin=ymin, color=pi), width=0.1) + 
  geom_point(aes(shape=envch_str), size=3) + 
  facet_grid(facets=r~pop_size, scales="free", space="free", labeller=tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1))
g = g + scale_color_brewer("Mutator", palette="Set1") +
  scale_y_log10() + #breaks=c(100,250,500,1000,2000,5000)) +
  scale_x_log10() +
  scale_linetype_manual("Mutator", values=c("dashed","solid","dotted")) + 
  scale_shape_manual("# Mutaions", values=c(16,2)) + 
  labs(y="Adaptation time\n", x="Mutational supply")
g
ggsave(filename=paste0("adaptation_NR_mut_supp_",today,".png"), plot=g, width=7, height=6)

# normalized by NM
data = dtt[phi=="NR"]
data = ddply(data, .(tau,r,phi,rho,pop_size,envch_str), summarize,
             CM=y[pi=="CM"]/y[pi=='NM'],
             SIM=y[pi=="SIM"]/y[pi=='NM'],
             mu.supp=as.double(tau[pi=='CM'])*as.double(unique(mu)[1])*as.double(as.character(unique(pop_size)[1])))
data=melt(data=data, measure=c("SIM","CM"))
names(data)<-c(names(data)[1:(dim(data)[2]-2)],'pi','y')

g = ggplot(data=data, 
           mapping=aes(x=as.numeric(tau), y=y, color=pi, group=interaction(pi,envch_str))) +
  theme_bw() + 
  geom_line(aes(linetype=pi), size=1) +   
  geom_point(aes(shape=envch_str), size=3) + 
  facet_grid(facets=pop_size~envch_str+r, scales="free", space="free", labeller=tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(y="Adaptation time relative to NM\n", x="Mutation rate increase")
g = g + scale_color_manual("Mutator", values=c('#377eb8', '#e41a1c')) +
  #scale_y_log10(breaks=c(100,250,500,1000,2000,5000)) +
  scale_x_log10() +
  scale_linetype_manual("Mutator", values=c("solid","dashed")) + 
  scale_shape_manual("# Mutaions", values=c(16,2))
g

ggsave(filename=paste0("adaptation_NR_tau",today,".png"), plot=g, width=7, height=6)

