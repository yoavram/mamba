today = Sys.Date()
print(paste("Today:",today))

dt = fread("mean_fitness_2013-12-17.csv")

dtt = dt[, c(mean=mean_se(mean.fitness), max=mean_se(max.fitness), min=mean_se(min.fitness)), by="pi,tau,r,tick"]
names(dtt)
#dtt = dt[, mean_se(mean.fitness), by="pi,tau,r,tick"]
dim(dtt)
names(dtt)

dtt[,r:=as.factor(r)]
dtt[,pi:=factor(pi, levels=c(0,1,1000), labels=c("CM","SIM","NM"))]
dtt[,tau:=as.factor(tau)]

g = ggplot(dtt, aes(x=tick, y=mean.y, group=pi, color=pi, fill=pi)) + facet_grid(.~r)
g1 = g + coord_cartesian(ylim=c(dtt[,min(mean.ymin, na.rm=T)]-0.025, dtt[,max(mean.ymax, na.rm=T)]+0.025), 
                         xlim=c(0,800)) + scale_color_brewer("Mutator",guide=F,palette="Set1") + scale_fill_brewer("Mutator",palette="Set1") + labs(x="generation", y="population mean fitness")
g2 = g1 + geom_ribbon(aes(ymin=mean.ymin, ymax=mean.ymax, fill=pi), alpha=0.2) + geom_line()
g2

#ggsave(plot=g2, filename=paste0("mean_fitness_", today, ".png"))

# test diff in slopes: http://stats.stackexchange.com/questions/33013/what-test-can-i-use-to-compare-slopes-from-two-or-more-regression-models?rq=1

dtt = dt[, c(mean=mean_se(mean.fitness), max=mean_se(max.fitness), min=mean_se(min.fitness)), by="pi,tau,r,tick"]
dtt[,r:=as.factor(r)]
dtt[,pi:=factor(pi, levels=c(0,1,1000), labels=c("CM","SIM","NM"))]
dtt[,tau:=as.factor(tau)]

g = ggplot(dtt[pi!='NM'], aes(x=tick, y=mean.y, group=pi, color=pi)) +
  facet_grid(r~.) + 
  scale_color_brewer("Mutator", palette="Set1") +
  scale_fill_brewer("Mutator", palette="Set1") +
  geom_line() +
  geom_ribbon(aes(ymin=min.y, ymax=max.y, fill=pi), alpha=0.2) +
  coord_cartesian(xlim=c(0,800)) +
  labs(x="Generation", y="Avg. Mean Fitness")
g
