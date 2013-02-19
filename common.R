library(ggplot2)
library(plyr)
library(rjson)
library(tools)
library(stringr)
library(gridExtra)

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

load.fitness.data <- function(jobname, filename) {
  filepath <- str_c('output/', jobname, '/fitness.', filename, '.csv')
  if (file.exists(filepath)) {
    data <- read.csv(filepath,header=T)
    return(data)
  } else {
    return(NULL)
  }
}

load.jobnames.list <- function(pattern="*") {
  files <- dir(path="output/",pattern=pattern)
  return(files)
}

load.files.list <- function(jobname) {
  files <- dir(path=str_c("output/",jobname,'/'),pattern="*.json")
  files <- file_path_sans_ext(files)
  return(files)
}

load.cmd.args <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  return(args)
}

datetime.string <- function() {
  return(format(Sys.time(), "%d_%m_%Y-%H_%M_%S"))
}