library(plyr)
library(ggplot2)
library(reshape2)
library(gridExtra)
library(data.table)

today = Sys.Date()

## analytic approximation
integrand1 <- function(s, pop_size, x) {
  res <- numeric(length = length(x))
  res[x==1] = 2*pop_size*s * (1 - exp(-2*pop_size*s))
  res[x!=1] = (1 - exp(-2*pop_size*s*x) - exp(-(1-x)) - exp(-2*pop_size*s))/(x*(1-x))
  return(res)
}

integrand2 <- function(s,pop_size,x) {
  res <- numeric(length = length(x))
  res[x==0] = 0
  res[x!=0] = (exp(2*pop_size*s*x) - 1) * (1 - exp(-2*pop_size*s*x))/(x*(1-x))
  return(res)
}

fixation_time <- function(s,pop_size,x) {
  df = data.frame(s=s,x=x,pop_size=pop_size)
  res = numeric(length = length(x))
  for(i in seq_along(x)) {
    s = df[i,]$s
    pop_size = df[i,]$pop_size
    x = df[i,]$x
    J1 = 2/(s*(1 - exp(-2*pop_size*s))) * integrate(function(t) {integrand1(s,pop_size,t)}, lower=x, upper=0.5)$value
    u = (1-exp(-2*pop_size*s*x))/(1-exp(-2*pop_size*s))
    J2 = 2/(s*(1-exp(-2*pop_size*s))) * integrate(function(t) {integrand2(s,pop_size,t)}, lower=0, upper=x)$value
    res[i] =  ( J1 + ((1-u)/u) * J2 )
  }
  return(res)
}
fixation_time(0.01, 1e5, 1e-5)


dt = fread("../adaptation_summary_2014-03-23.csv")
dt$real.tau = dt$tau
dt[pi==1000]$real.tau = 1

dtt = dt[, mean_se(final_tick), by="s,beta,pi,r,phi,rho,pop_size,envch_str,mu,num_loci,real.tau"]

dtt[,pi:=factor(dtt$pi,levels=c(0,1,1000),labels=c("CM","SIM","NM"))]
dtt[,phi:=factor(dtt$phi,levels=c(0,1,1000),labels=c("CR","SIR","NR"))]


dtt[, appearance_prob:= exp(-real.tau*mu/s) * (beta) * real.tau*mu * exp(-real.tau*mu) / num_loci]
dtt[, fixation_prob:= (1-exp(-2*s))/(1-exp(-2*pop_size*s))]
dtt[, fixation_prob0:= 2*s] # just as good because the population is very large
dtt[, fixation_time:= fixation_time(s,pop_size,1/pop_size)]
dtt[, adaptation_time:=envch_str*(fixation_time+1/(pop_size*appearance_prob*fixation_prob))]

qplot(y=y, x=adaptation_time, data=dtt, color=factor(real.tau)) + 
geom_abline(aes(slope=1, intercept=0)) + facet_grid(envch_str~., scales="free")

ggplot(data=subset(dtt, r==0 & phi=='NR'), mapping=aes(x=pop_size*real.tau, color=pi)) + 
  geom_point(aes(y=y), size=2) + 
  geom_errorbar(aes(y=y,ymax=ymax, ymin=ymin), width=0.3) +   
  facet_grid(envch_str~pi, labeller=tau_label, scales="free"  ) +
  geom_line(aes(y=adaptation_time)) + 
  scale_color_brewer("Mutator", palette="Set1", guide='none') +
  scale_y_log10() + scale_x_log10() + 
  labs(x="Mutational supply", y="Adaptation time")

ggsave(plot=g, filename="adaptation_time_approx.png", width=12, height=8)

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

