today = Sys.Date()

dt = fread("../adaptation_summary_2014-03-23.csv")

dtt = dt[, mean_se(final_tick), by="pi,tau,r,phi,rho,pop_size,envch_str"]

dtt[,r:=as.factor(r)]
dtt[,pi:=factor(dtt$pi,levels=c(0,1,1000),labels=c("CM","SIM","NM"))]
dtt[,phi:=factor(dtt$phi,levels=c(0,1,1000),labels=c("CR","SIR","NR"))]
dtt[,tau:=as.factor(tau)]
dtt[,rho:=as.factor(rho)]
dtt[,pop_size:=as.factor(pop_size)]
dtt[,envch_str:=as.factor(envch_str)]

# Overview
data = dtt[phi=="NR"]
g = ggplot(data=data, mapping=aes(x=r, y=y, color=pi, group=interaction(pi,envch_str))) +
  theme_bw() + 
  geom_line(aes(linetype=pi), size=1) +   
  geom_errorbar(aes(y=y,ymax=ymax, ymin=ymin, color=pi), width=0.3) + 
  geom_point(aes(shape=envch_str), size=3) + 
  facet_grid(facets=pop_size~tau, scales="free", labeller=tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(y="Adaptation time\n", x="Recombination rate")
g = g + scale_color_brewer("Mutator", palette="Set1") +
  #scale_y_log10(breaks=c(100,250,500,1000,2000,5000)) +
  scale_linetype_manual("Mutator", values=c("dashed","solid","dotted")) + 
  scale_shape_manual("# Mutaions", values=c(16,2))
g
ggsave(filename=paste0("adaptation_NR_",today,".png"), plot=g, width=7, height=6)

# normalized by NM
data = ddply(data, .(tau,r,phi,rho,pop_size,envch_str), summarize, 
      CM=y[pi=="CM"]/y[pi=='NM'],
      SIM=y[pi=="SIM"]/y[pi=='NM'])
data=melt(data=data, measure=c("SIM","CM"))
names(data)<-c(names(data)[1:(dim(data)[2]-2)],'pi','y')
g = ggplot(data=data, mapping=aes(x=r, y=y, color=pi, group=interaction(pi,envch_str))) +
  theme_bw() + 
  geom_line(aes(linetype=pi), size=1) +   
  geom_point(aes(shape=envch_str), size=3) + 
  facet_grid(facets=pop_size~tau, scales="free", labeller=tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(y="Adaptation time relative to NM\n", x="Recombination rate")
g = g + scale_color_manual("Mutator", values=c('#377eb8', '#e41a1c')) +
  #scale_y_log10(breaks=c(100,250,500,1000,2000,5000)) +
  scale_linetype_manual("Mutator", values=c("solid","dashed")) + 
  scale_shape_manual("# Mutaions", values=c(16,2))
g
ggsave(filename=paste0("adaptation_NR_",today,".png"), plot=g, width=7, height=6)
