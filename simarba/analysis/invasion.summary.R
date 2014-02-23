today = Sys.Date()

df1 = fread("invasion_summary_2013-11-17.csv")
df2 = fread("invasionbig_summary_2013-11-20.csv")
df2 = subset(df2, select=-c(adapt))
df3 = fread("invasion_rb_summary_2013-11-19.csv")
df3 = subset(df3, select=-c(adapt))

dt = rbind(df1, df2, df3)

dtt = dt[in_phi==1000 & beta<1 & rb==F & pop_size<1e8 & s==0.1, mean_se(in_final_rate), by="pi,tau,rho,phi,r,pop_size,envch_str,in_pi,in_tau,in_rho,in_phi,in_rate,beta,rb,mu,s,envch_start"]
dim(dtt)

dtt[,r:=as.factor(r)]
dtt[,pi:=factor(dtt$pi,levels=c(0,1,1000),labels=c("CM","SIM","NM"))]
dtt[,tau:=as.factor(tau)]
dtt[,in_pi:=factor(dtt$in_pi,levels=c(0,1,1000),labels=c("CM","SIM","NM"))]
dtt[,in_tau:=as.factor(in_tau)]
dtt[,pop_size:=as.factor(pop_size)]


g = ggplot(data=dtt, mapping=aes(x=r,y=y)) + facet_grid(drop=T,facets=pop_size+envch_str~in_tau) +
  labs(y="invader rate", x="recombination rate")
g1 = g + geom_line(aes(color=in_pi,group=in_pi))
g2 = g1  + geom_errorbar(aes(ymax=ymax,ymin=ymin), position="dodge", width=0.2) + 
  scale_color_brewer("invader", palette="Set1") +
  theme(axis.text.x = element_text(angle = 270, hjust = 1))
g2

ggsave(filename=paste0("invasion_",today,".png"), plot=g2)


g = ggplot(data=dtt[in_pi!="NM" & in_tau!=100 & pop_size==1e6 & envch_str==4], mapping=aes(x=r, y=y, ymin=ymin, ymax=ymax, group=in_pi)) + 
  facet_grid(facets=in_tau~., labeller = label_bquote(tau == .(x))) +
  scale_color_brewer("Invader", palette="Set1", guide = FALSE) +
  theme(text = element_text(size=16), axis.text = element_text(size=11), axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Recombination rate", y="Fixation Probability\n") + 
  geom_errorbar(aes(color=in_pi), size=0.5, width=0.2) + 
  geom_line(aes(color=in_pi, linetype=in_pi), size=1) + 
  geom_hline(y=0.5, color="black", linestyle="dashed") + 
  scale_y_continuous(limits=c(0.1,0.9), breaks=c(0.25,0.5,0.75)) + 
  scale_linetype_manual("Invader", values=c("dashed","solid"), guide = FALSE)
g
ggsave(filename=paste0("invasion_SIMvsCM_", today, ".png"), plot=g, width=4, height=6)


