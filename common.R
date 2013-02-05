library(ggplot2)
library(plyr)
library(rjson)
library(tools)
library(stringr)

load.params <- function(filename) {
  filepath <- str_c('output/', filename, '/', filename, ".json")
  if (file.exists(filepath)) {
    params <- fromJSON(file=filepath)
    return(params)
  } else {
    return(NULL)
  }
}

load.data <- function(filename) {
  filepath <- str_c('output/', filename, '/', filename, '.csv.gz')
  if (file.exists(filepath)) {
    data <- read.csv(filepath,header=T)
    return(data)
  } else {
    return(NULL)
  }
}

load.files.list <- function() {
  files <- dir(path="output/",pattern="*")
  # TODO
  return(files)
}