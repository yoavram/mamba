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

fixation_time <- function(s,pop_size,x,y) {
  df = data.frame(s=s,x=x,pop_size=pop_size,y=y)
  res = numeric(length = length(x))
  for(i in seq_along(x)) {
    s = df[i,]$s    
    pop_size = df[i,]$pop_size
    x = df[i,]$x
    y = df[i,]$y
    J1 = 2/(s*(1 - exp(-2*pop_size*s))) * integrate(function(t) {integrand1(s,pop_size,t)}, lower=x, upper=y)$value
    u = (1-exp(-2*pop_size*s*x))/(1-exp(-2*pop_size*s))
    J2 = 2/(s*(1-exp(-2*pop_size*s))) * integrate(function(t) {integrand2(s,pop_size,t)}, lower=0, upper=x)$value
    res[i] =  ( J1 + ((1-u)/u) * J2 )
  }
  return(res)
}
fixation_time(0.01, 1e5, 1e-5, 0.5)

fixation_prob <- function(s,pop_size,mu,tau,pi) {
  res = numeric(length = length(pi))
  res[pi!="SIM"] = (exp(-tau*mu) * (1 - exp(-2*(1/(1-s)-1))))[pi!="SIM"]
  res[pi=="SIM"] = (exp(-tau*mu) * (1 - exp(-2*(exp(mu*(tau-1))/(1-s)-1))))[pi=="SIM"]
  return(res)
}

dt = fread("../adaptation_summary_2014-06-17.csv")

dtt = dt[phi==0 & rho==1, mean_se(final_tick), by="s,beta,pi,r,phi,rho,pop_size,envch_str,mu,num_loci,tau"]

dtt[,pi:=factor(dtt$pi,levels=c(0,1,1000),labels=c("CM","SIM","NM"))]
dtt[,phi:=factor(dtt$phi,levels=c(0,1,1000),labels=c("CR","SIR","NR"))]

dtt[, appearance_prob:= beta * tau * mu / num_loci]
dtt[, fixation_prob:=   fixation_prob(s,pop_size,mu,tau,pi)]
dtt[, fixation_time:=   fixation_time(s,pop_size,1/pop_size,0.5)]
dtt[, adaptation_time:= envch_str*(fixation_time+1/(1-(1-appearance_prob*fixation_prob)^pop_size))]
      
g=ggplot(data=dtt[r==0], mapping=aes(x=pop_size*tau*mu, color=pi)) + 
  geom_point(aes(y=y), size=2) + 
  geom_errorbar(aes(y=y,ymax=ymax, ymin=ymin), width=0.3) +   
  facet_grid(envch_str~pi, labeller=tau_label, scales="free"  ) +
  geom_line(aes(y=adaptation_time, linetype=pi)) + 
  scale_color_brewer("Mutator", palette="Set1", guide='none') +
  scale_y_log10() + scale_x_log10() + scale_linetype(guide="none") +
  labs(x="Mutational supply", y="Adaptation time") 
g

qplot(x=adaptation_time, y=y, data=dtt, color=factor(pi), size=I(3)) + 
  labs(y="observed",x="expected",title="adaptation time") +
  geom_errorbar(aes(ymax=ymax,ymin=ymin)) +
  geom_abline(aes(slope=1, intercept=0)) + 
  facet_grid(envch_str~., scales="free") + 
  scale_color_brewer("Strategy", palette="Set1") +
  scale_x_log10() +   scale_y_log10()

# factors
dtt[,pop_size:=as.factor(pop_size)]
dtt[,r:=as.factor(r)]
dtt[,tau:=as.factor(tau)]
dtt[,rho:=as.factor(rho)]
dtt[,pop_size:=as.factor(pop_size)]
dtt[,envch_str:=as.factor(envch_str)]

# Overview
data = dtt[pop_size!=1e8 & rho==1 & tau==5]# & pi!="NM"]
g = ggplot(data=data,
           mapping=aes(x=r, y=y, color=pi, group=interaction(pi,envch_str,tau))) +
  theme_bw() + 
  #geom_line(aes(linetype=tau), size=1) +   
  geom_errorbar(aes(y=y,ymax=ymax, ymin=ymin, color=pi), width=0.4) + 
  geom_point(aes(shape=pi), size=3) + 
  facet_grid(facets=pop_size~envch_str, scales="free", labeller=tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(y="Adaptation time\n", x="Recombination rate")
g = g + scale_color_brewer("Mutator", palette="Set1") +
  stat_smooth(method="lm", se=FALSE) + 
  scale_shape(guide="none") + 
  scale_linetype(guide="none") +
  geom_line(aes(y=adaptation_time), size=0.2, linetype='dashed')
g

ggsave(filename=paste0("adaptation_NR_",today,".png"), plot=g, width=7, height=6)

# mutational supply
data = dtt[pop_size!=1e8 & rho==1]
g = ggplot(data=data,
           mapping=aes(x=as.numeric(tau)*as.numeric(mu)*as.numeric(pop_size), y=y, color=pi, group=interaction(pi,envch_str))) +
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

# normalize by NM
data = dtt[pop_size!=1e8 & rho==1]
data = dcast(data[tau==5 | tau==1], r+envch_str+pop_size~pi, value.var="y")
data = ddply(data, .(r,envch_str,pop_size), summarize,
             CM=CM/NM,
             SIM=SIM/NM
)
data = melt(data, variable.names=.("CM","SIM"))

g = ggplot(data=data, mapping=aes(x=r, y=value, group=variable, color=variable)) +
  geom_point() +
  stat_smooth(method="lm", se=F) +
  facet_grid(facets=pop_size~envch_str, scales="free", space="free", labeller=tau_label) +
  labs(x="Recombination rate", y="Adaptation time relative to NM") +
  scale_color_brewer(name="Mutator", palette="Set1") +
  theme_bw() +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1))
g
