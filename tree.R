library(Rgraphviz)

create.initial.tree <- function(strain="0") {
  g <- graphNEL()
  g <- addNode(strain, g)
  return(g)
}

add.strain <- function(tree, new.strain, parent.strain) {
  tree <- addNode(new.strain, tree)
  tree <- addEdge(parent.strain, new.strain, tree)
  return(tree)
}

kill.strains <- function(tree, live.strains) {
  nodes <- buildNodeList(tree)
  for (node in nodes) {
    if(!node@name %in% live.strains) {
      nodes[node@name][[1]]@attrs$fillcolor <- "black"
      nodes[node@name][[1]]@attrs$fontcolor <- "white"
    }
  }
  return(nodes)
}

plot.tree <- function(tree, live.strains=NULL) {
  if (is.null(live.strains)) {
    live.strains <- nodes(tree)
  }
  nodes <- kill.strains(tree, live.strains)
  edges <- buildEdgeList(tree)
  plot(agopen(name="", nodes=nodes, edges=edges, edgeMode="undirected"))
  
}

test.tree <- function() {
  g <- create.initial.tree()
  g <- add.strain(g, "1", "0")
  g <- add.strain(g, "10", "0")
  g <- add.strain(g, "13", "10")
  g <- add.strain(g, "11", "10")
  g <- add.strain(g, "33", "0")
  g <- add.strain(g, "22", "0")
  g <- add.strain(g, "333", "22")
  g <- add.strain(g, "332", "333")
  
  plot.tree(g)
  
  plot.tree(g, c("333", "22", "11"))
}
