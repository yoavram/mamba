library(ggplot2)
library(plyr)

# plots

# strains
qplot(x=1:length(population),y=population,log="y",main="individuals per strain", xlab="strain", ylab="individuals")
qplot(population, geom=c("histogram","density"))

# num of mutations
mutation.load <- apply(genomes, 1, sum)
qplot(x=mutation.load, y=population,log="y", geom="point",main="individuals per mutation load", xlab="mutation load", ylab="individuals") + stat_smooth(method=lm)

qplot(x=fitness, y=population,log="y", geom="point",main="individuals per fitness", xlab="fitness", ylab="individuals") + stat_smooth(method=lm)

df <- data.frame(count=population, fitness=fitness, mutation.load=mutation.load)
fs <- ddply(df, .(mutation.load), summarize, count = sum(count))
fs <- cbind(fs, expected=dpois(0:max(fs$mutation.load), mu.rate/s)*sum(population))

p <- ggplot(fs, aes(mutation.load, expected)) 
p + geom_point()

points(fs$expected, col="red")
plot(fs$count)