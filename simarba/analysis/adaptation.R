today = Sys.Date()

dt = fread("adaptation_summary_2013-11-20.csv")

dtt = dt[tau>1, mean_se(final_tick), by="pi,tau,r,pop_size,envch_str"]

dtt[,r:=as.factor(r)]
dtt[,pi:=factor(dtt$pi,levels=c(0,1,1000),labels=c("CM","SIM","NM"))]
dtt[,tau:=as.factor(tau)]
dtt[,pop_size:=as.factor(pop_size)]

g = ggplot(data=dtt,mapping=aes(x=r,y=y)) +
  facet_grid(facets=pop_size+envch_str~tau, scales="free") +
  labs(y="adaptation time", x="recombination rate") 
  #scale_y_log10()
g1 = g + geom_point(aes(color=pi,group=pi), size=2)  + scale_color_brewer("mutator", palette="Set1")
g2 = g1 + geom_errorbar(aes(y=y,ymax=ymax, ymin=ymin, color=pi), width=0.1)
g3 = g2 + geom_smooth(aes(group=pi,color=pi), method="lm", se=F, size=1)

ggsave(plot=g3, filename=paste0("adaptation_",today,".png"))