library(Rgraphviz)

load("~/lecs/workspace/mamba/trees/msb_2012_Nov_12_14_38_53.RData")

nodez = as.numeric(nodes(tree))
edgez <- edges(tree)

plot(log(sort(nodez)))

deg = degree(tree) # all(unlist(lapply(edgez, length))==deg)
mean(deg)
mean(tail(deg, -1))
plot(log(deg) ~ log(nodez))
plot(log(tail(deg, -1)) ~ log(tail(nodez, -1)))
hist(tail(deg, -1), breaks=30)

conn <- connComp(tree)
length(conn)==1

#tree.AM <- as(tree, "graphAM")

mat <- as(tree, "matrix")
library(network)
net <- as.network.matrix(mat)
plot.network(net)