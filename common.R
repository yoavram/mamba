library(ggplot2)
library(plyr)
library(rjson)
library(tools)
library(stringr)

load.params <- function(filename) {
  params <- fromJSON(file=str_c('output/', filename, '/', filename, ".json"))
  return(params)
}

load.data <- function(filename) {
  data <- read.csv(str_c('output/', filename, '/', filename, '.csv.gz'),header=T)
  return(data)
}

load.files.list <- function() {
  files <- dir(path="output/",pattern="*")
  files <- files[files!='tmp']
  return(files)
}