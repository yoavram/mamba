#library(Rsge)
library(plyr)
library(rjson)
setwd("~/workspace/mamba/simarba")

#sge.options(sge.qsub.options="-cwd -V -l lilach,mem_free=1G")
#sge.options(sge.remove.files=TRUE)
#sge.options(sge.use.cluster=FALSE)

today = Sys.Date()
#setTimeLimit(cpu = 0.5)

jobname = "adaptation"

print(paste("Starting", jobname))
filenames = list.files(paste0("../output/",jobname), pattern="*.json", full.names=TRUE)

f = function(x) {
 # print(x)
  return(as.data.frame(suppressWarnings(fromJSON(file=x))))
}

#df <- sge.parLapply(filenames, f, packages=c("rjson"), njobs=400)

df = ldply(filenames, f)

write.csv(df, file=paste0(jobname,"_summary_",today,".csv"))
print(paste("Done writing table with dimensions", as.character(dim(df)[1])))
      
