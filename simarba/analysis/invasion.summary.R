tau_label = function(variable,value){
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
  else{
    quoted <- substitute(.(x))
  }
  lapply(value, function(x)
    eval(substitute(bquote(expr, list(x = x)), list(expr = quoted))))
}


today = Sys.Date()

df1 = fread("invasion_summary_2013-11-17.csv")
df2 = fread("invasionbig_summary_2013-11-20.csv")
df2 = subset(df2, select=-c(adapt))
df3 = fread("invasion_rb_summary_2013-11-19.csv")
df3 = subset(df3, select=-c(adapt))

dt = rbind(df1, df2, df3)

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
data=dtt[rb==F & in_phi=="NR" & in_pi!="NM" & in_tau!=100 & pop_size==1e6 & envch_str==4 & beta<1]
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
data=dtt[rb==F & in_phi=="NR" & in_pi!="NM" & in_tau!=100 & pop_size==1e5 & envch_str==4 & in_tau!=20]
g = ggplot(mapping=aes(x=r, y=y, ymin=ymin, ymax=ymax, group=in_pi), data=data) + 
  theme_bw() +  
  facet_grid(facets=in_tau~beta, labeller = tau_label) +  
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Recombination rate", y="Fixation Probability\n") + 
  geom_errorbar(aes(color=in_pi), size=0.5, width=0.2) + 
  geom_line(aes(color=in_pi, linetype=in_pi), size=1) + 
  geom_hline(y=0.5, color="black", linestyle="dashed") + 
  scale_y_continuous(limits=c(0.0,1.0), breaks=c(0,0.25,0.5,0.75,1)) 
g = g + scale_color_brewer("Invader", palette="Set1", guide = FALSE) +
  scale_linetype_manual("Invader", values=c("dashed","solid","dotted"), guide = FALSE)
g
ggsave(filename=paste0("invasion_SIMvsCMvsNM_pop_1e5_", today, ".png"), plot=g, width=4, height=6)

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
data = dtt[rb==F & in_phi!="NR" & in_pi=="NM" & envch_str==4 & beta<1 & in_rho!=100 & in_rho!=20 & pop_size != 1e7]
g = ggplot(mapping=aes(x=r, y=y, ymin=ymin, ymax=ymax, group=in_phi), data=data) + 
  theme_bw() +
  facet_grid(facets=in_rho~pop_size, labeller = tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Recombination rate", y="Fixation Probability\n") + 
  geom_errorbar(aes(color=in_phi), size=0.5, width=0.2) + 
  geom_line(aes(color=in_phi, linetype=in_phi), size=1) + 
  geom_hline(y=0.5, color="black", linestyle="dashed") + 
  scale_y_continuous(limits=c(0.0,1.0), breaks=c(0,0.25,0.5,0.75,1))
g = g + scale_color_manual("", values=c("#984ea3", "#ff7f00")) + #, guide = FALSE) +
  scale_linetype_manual("", values=c("dashed","solid","dotted"))#, guide = FALSE)
g
ggsave(filename=paste0("invasion_SIRvsCR_pop_sizes_", today, ".png"), plot=g, width=5, height=6)

#Figure 5: recombinator+mutator
data = dtt[rb==F & envch_str==4 & beta<1 & in_tau==5 & pop_size!=1e7]
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


# Figure S1: pop size
data = dtt[rb==F & in_pi != "NM" & beta<1 & in_phi=="NR" & r==0 & in_tau != 20 & in_tau != 100]
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

# Figure RB
data=dtt[in_phi=="NR" & in_tau!=100 & pop_size==1e6 & envch_str==4 & beta<1]
g = ggplot(mapping=aes(x=r, y=y, ymin=ymin, ymax=ymax, group=in_pi), data=data) +
  theme_bw() +
  facet_grid(facets=in_tau~rb, labeller = tau_label) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Recombination rate", y="Fixation Probability\n") + 
  geom_errorbar(aes(color=in_pi), size=0.5, width=0.2) + 
  geom_line(aes(color=in_pi, linetype=in_pi), size=1) + 
  geom_hline(y=0.5, color="black", linestyle="dashed") + 
  scale_y_continuous(limits=c(0.1,0.9), breaks=c(0.25,0.5,0.75))
g = g + scale_color_brewer("", palette="Set1") + #, guide = FALSE) +
  scale_linetype_manual("", values=c("dashed","solid", "dotted")) #, guide = FALSE)
g
#ggsave(filename=paste0("invasion_SIMvsCM_pop_1e6_", today, ".png"), plot=g, width=4, height=6)
