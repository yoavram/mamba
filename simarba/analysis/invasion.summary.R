library(data.table)
library(ggplot2)

tau_label = function(variable,value) {
  value <- as.character(value)  
  if (variable=='in_tau') {
    quoted <- substitute(tau==.(x))
  } 
  else if (variable=='tau') {
    quoted <- substitute(tau==.(x))
  } 
  else if (variable=='beta') {
    quoted <- substitute(beta==.(x))
  }
  else if (variable=='pop_size') {
    quoted <- substitute(N==.(x))
  }
  else if (variable=='in_rho') {
    quoted <- substitute(rho==.(x))
  }
  else if (variable=='r') {
    quoted <- substitute(r==.(x))
  }
  else if (variable=='envch_str') {
    quoted <- substitute(changes==.(x))
  }
  else{
    quoted <- substitute(.(x))
  }
  lapply(value, function(x)
    eval(substitute(bquote(expr, list(x = x)), list(expr = quoted))))
}


today = Sys.Date()
setwd("simarba/analysis/")

dt = fread("../invasion_summary_2014-08-25.csv")
#qplot(x=factor(in_pi),y=factor(in_tau),data=dt)

dtt = dt[pop_size<1e8 & s==0.1, mean_se(in_final_rate), by="pi,tau,rho,phi,r,pop_size,envch_str,in_pi,in_tau,in_rho,in_phi,in_rate,beta,rb,mu,s,envch_start"]
dim(dtt)

dtt[,r:=as.factor(r)]
dtt[,pi:=factor(dtt$pi,levels=c(0,1,1000),labels=c("CM","SIM","NM"))]
dtt[,phi:=factor(dtt$phi,levels=c(0,1,1000),labels=c("CR","SIR","NR"))]
dtt[,tau:=as.factor(tau)]
dtt[,rho:=as.factor(rho)]
dtt[,in_pi:=factor(dtt$in_pi,levels=c(0,1,1000),labels=c("CM","SIM","NM"))]
dtt[,in_phi:=factor(dtt$in_phi,levels=c(0,1,1000),labels=c("CR","SIR","NR"))]
dtt[,in_tau:=as.factor(in_tau)]
dtt[,in_rho:=as.factor(in_rho)]
dtt[,pop_size:=as.factor(pop_size)]

# Figure 1
data=dtt[rb==F & in_phi=="NR" & in_pi!="NM" & pop_size==1e6 & envch_str==4 & beta<1]
g = ggplot(mapping=aes(x=r, y=y, ymin=ymin, ymax=ymax, group=in_pi), data=data) +
  theme_bw() +
  facet_grid(facets=in_tau~., labeller = label_bquote(tau == .(x))) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Recombination rate", y="Fixation Probability\n") + 
  geom_errorbar(aes(color=in_pi), size=0.5, width=0.2) + 
  geom_line(aes(color=in_pi, linetype=in_pi), size=1) + 
  geom_hline(y=0.5, color="black", linestyle="dashed") + 
  scale_y_continuous(limits=c(0.1,0.9), breaks=c(0.25,0.5,0.75))
g = g + scale_color_brewer("", palette="Set1") + #, guide = FALSE) +
  scale_linetype_manual("", values=c("dashed","solid")) #, guide = FALSE)
g
ggsave(filename=paste0("invasion_SIMvsCM_pop_1e6_", today, ".png"), plot=g, width=4, height=6)

# Figure 2: beta
data=dtt[rb==F & in_phi=="NR" & in_pi!="NM" & envch_str==4]
g = ggplot(mapping=aes(x=r, y=y, ymin=ymin, ymax=ymax, group=in_pi), data=data) + 
  theme_bw() +  
  facet_grid(facets=in_tau~pop_size+beta, labeller = tau_label) +  
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Recombination rate", y="Fixation Probability\n") + 
  geom_errorbar(aes(color=in_pi), size=0.5, width=0.2) + 
  geom_line(aes(color=in_pi, linetype=in_pi), size=1) + 
  geom_hline(y=0.5, color="black", linestyle="dashed") + 
  scale_y_continuous(limits=c(0.0,1.0), breaks=c(0,0.25,0.5,0.75,1)) 
g = g + scale_color_brewer("Invader", palette="Set1", guide = FALSE) +
  scale_linetype_manual("Invader", values=c("dashed","solid","dotted"), guide = FALSE)
g
ggsave(filename=paste0("invasion_beta_SIMvsCM_pop_sizes_", today, ".png"), plot=g, width=6, height=6)

# Figure 3: pop size
data=dtt[rb==F & in_phi=="NR" & in_pi!="NM" & in_tau!=100 & envch_str==4 & in_tau!=20 & beta<1]
g = ggplot(mapping=aes(x=r, y=y, ymin=ymin, ymax=ymax, group=in_pi), data=data) + 
  theme_bw() +
  facet_grid(facets=in_tau~pop_size, labeller = tau_label) +  
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Recombination rate", y="Fixation Probability\n") + 
  geom_errorbar(aes(color=in_pi), size=0.5, width=0.2) + 
  geom_line(aes(color=in_pi, linetype=in_pi), size=1) + 
  geom_hline(y=0.5, color="black", linestyle="dashed") + 
  scale_y_continuous(limits=c(0.0,1.0), breaks=c(0,0.25,0.5,0.75,1))
g = g + scale_color_brewer("Invader", palette="Set1", guide = FALSE) +  
  scale_linetype_manual("Invader", values=c("dashed","solid","dotted"), guide = FALSE)
g
ggsave(filename=paste0("invasion_SIMvsCMvsNM_pop_sizes_", today, ".png"), plot=g, width=4, height=6)

#Figure 4: recombinator
data = dtt[rb==F & r!=1e-16 & in_pi=="NM" & envch_str==4 & beta<1]
g = ggplot(mapping=aes(x=r, y=y, ymin=ymin, ymax=ymax, group=in_phi), data=data) + 
  theme_bw() +
  facet_grid(facets=in_rho~pop_size)+#, labeller = tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Recombination rate", y="Fixation Probability\n") + 
  geom_errorbar(aes(color=in_phi), size=0.5, width=0.2) + 
  geom_line(aes(color=in_phi, linetype=in_phi), size=1) + 
  geom_hline(y=0.5, color="black", linestyle="dashed") + 
  scale_y_continuous(limits=c(0.0,1.0), breaks=c(0,0.25,0.5,0.75,1))
g = g + scale_color_manual("", values=c("#984ea3", "#ff7f00")) + #, guide = FALSE) +
  scale_linetype_manual("", values=c("dashed","solid","dotted"))#, guide = FALSE)
g
ggsave(filename=paste0("invasion_NRvsCR_pop_sizes_", today, ".png"), plot=g, width=5, height=6)

#Figure 5: recombinator+mutator
data = dtt[rb==F & r!=1e-16 & envch_str==4 & beta<1 & (in_tau==5 | in_tau==1)]
g = ggplot(mapping=aes(x=r, y=y, ymin=ymin, ymax=ymax, group=in_pi), data=data) + 
  theme_bw() +
  facet_grid(facets=pop_size~in_phi, labeller = tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Recombination rate", y="Fixation Probability\n") + 
  geom_errorbar(aes(color=in_pi), size=0.5, width=0.2) + 
  geom_line(aes(color=in_pi, linetype=in_pi), size=1) + 
  geom_hline(y=0.5, color="black", linestyle="dashed") + 
  scale_y_continuous(limits=c(0.0,1.0), breaks=c(0,0.25,0.5,0.75,1))
g = g +  scale_color_brewer("", palette="Set1") + #, guide = FALSE) +
  scale_linetype_manual("", values=c("dashed","solid","dotted"))#, guide = FALSE)
g
ggsave(filename=paste0("invasion_combined_tau_5_pop_sizes_", today, ".png"), plot=g, width=6, height=6)


#Figure 5b: recombinator+mutator
data = dtt[rb==F & r!=1e-16 & envch_str==4 & beta<1 & pop_size==1e6]
data$in_tau = as.numeric(levels(data$in_tau))[data$in_tau]
g = ggplot(mapping=aes(x=in_tau, y=y, ymin=ymin, ymax=ymax, group=in_pi), data=data) + 
  theme_bw() +
  facet_grid(facets=r~in_phi, labeller = tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Modifier effect", y="Fixation Probability\n") + 
  geom_errorbar(aes(color=in_pi), size=0.5, width=0.2) + 
  geom_line(aes(color=in_pi, linetype=in_pi), size=1) + 
  geom_hline(y=0.5, color="black", linestyle="dashed") + 
  scale_y_continuous(limits=c(0.0,1.0), breaks=c(0,0.25,0.5,0.75,1))
g = g +  scale_color_brewer("", palette="Set1") + #, guide = FALSE) +
  scale_linetype_manual("", values=c("dashed","solid","dotted"))#, guide = FALSE)
g
ggsave(filename=paste0("invasion_combined2_tau_5_pop_sizes_", today, ".png"), plot=g, width=6, height=6)


# Figure S1: pop size
data = dtt[rb==F & in_pi != "NM" & beta<1 & in_phi=="NR" & r==0]
g = ggplot(mapping=aes(x=pop_size, y=y, ymin=ymin, ymax=ymax, group=in_pi), data=data) + 
  theme_bw() +
  facet_grid(facets=in_tau~envch_str, labeller = tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Population size", y="Fixation Probability\n") + 
  geom_errorbar(aes(color=in_pi), size=0.5, width=0.2) + 
  geom_line(aes(color=in_pi, linetype=in_pi), size=1) + 
  geom_hline(y=0.5, color="black", linestyle="dashed") + 
  scale_y_continuous(limits=c(0.0,1.0), breaks=c(0,0.25,0.5,0.75,1))
g = g +  scale_color_brewer("", palette="Set1", guide = FALSE) +
  scale_linetype_manual("", values=c("dashed","solid","dotted"), guide = FALSE)
g
ggsave(filename=paste0("invasion_SIMvsCM_r_0", today, ".png"), plot=g, width=4, height=6)

# Figure S2 RB
data=dtt[(in_phi=="NR" | in_rho==1) & in_pi!="NM"  & envch_str==4 & beta<1]
g = ggplot(mapping=aes(x=r, y=y, ymin=ymin, ymax=ymax, group=interaction(rb,in_pi)), data=data) +
  theme_bw() +
  facet_grid(facets=in_tau~pop_size, labeller = tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Recombination rate", y="Fixation Probability\n") + 
  geom_errorbar(aes(color=in_pi), size=0.5, width=0.2) + 
  geom_line(aes(color=in_pi, linetype=rb), size=1) + 
  geom_hline(y=0.5, color="black", linestyle="dashed") + 
  scale_y_continuous(limits=c(0.1,0.9), breaks=c(0.25,0.5,0.75))
g = g + scale_color_brewer("", palette="Set1") + #, guide = FALSE) +
  scale_linetype_manual("", values=c("dashed","solid", "dotted")) #, guide = FALSE)
g
ggsave(filename=paste0("invasion_RB_SIMvsCM_pop_1e6_", today, ".png"), plot=g, width=6, height=6)


#Figure 5 - heatmap
data = dtt[rb==F & envch_str==4 & beta<1 & pop_size==1e6]
g = ggplot(mapping=aes(x=in_tau, y=r), data=data) + 
  theme_bw() +
  facet_grid(facets=in_phi~in_pi, labeller = tau_label, as.table=F) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Modifier Effect", y="Recombination Rate")  

g = g + geom_tile(mapping=aes(fill=y)) + 
  scale_fill_gradient2("Fixation\nProbability", midpoint=0.5, limits=c(0.0,1.0), breaks=c(0,0.5,1),
                       low="darkred", mid="white", high="steelblue", na.value="black")
                       #low="#ef8a62", mid="#f7f7f7", high="#67a9cf", na.value="gray50")
ann_text <- data.frame(in_tau="5", r="0.003",
                           in_pi="NM", in_phi="NR")
g = g + geom_text(data=ann_text,label="\nControl", size=8, color="gray50")
g
gsave(filename=paste0("invasion_combined_heatmap_N_1e6_", today, ".png"), plot=g, width=7, height=6)

# Figure 5 - asexuals vs recombinators
data=dtt[rb==F & r==3e-14 & envch_str==4 & beta<1]
data[,eff_r:=factor(as.numeric(as.character(data$in_rho))*as.numeric(as.character(data$r)))]
g = ggplot(mapping=aes(x=eff_r, y=y, ymin=ymin, ymax=ymax, group=in_pi), data=data) +
  theme_bw() +
  facet_grid(facets=.~in_phi, labeller = tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Modifier's Recombination Rate", y="Fixation Probability\n") + 
  geom_errorbar(aes(color=in_pi), size=0.5, width=0.2) + 
  geom_line(aes(color=in_pi, linetype=in_pi), size=1) + 
  geom_hline(y=0.5, color="black", linestyle="dashed") + 
  scale_y_continuous(limits=c(0.1,0.9), breaks=c(0.25,0.5,0.75))
g = g + scale_color_brewer("", palette="Set1")+#, guide = FALSE) +
  scale_linetype_manual("", values=c("dashed","solid","dotted"), guide = FALSE)
g
ggsave(filename=paste0("invasion_SIMvsCMvsNM_asexuals_", today, ".png"), plot=g, width=7, height=6)
