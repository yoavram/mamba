library(ggplot2)
library(plyr)
library(rjson)
library(tools)
library(stringr)

load.params <- function(jobname, filename) {
  filepath <- str_c('output/', jobname, '/', filename, ".json")
  if (file.exists(filepath)) {
    params <- fromJSON(file=filepath)
    return(params)
  } else {
    return(NULL)
  }
}

load.data <- function(jobname, filename) {
  filepath <- str_c('output/', jobname, '/', filename, '.csv.gz')
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

load.cmd.args <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  return(args)
}