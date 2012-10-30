debug = TRUE 
num.loci = 1000
num.alleles = 2
pop.size = 100000
s = 0.01
mu.rate = 0.003
rec.rate = 0.06
max.tick = 100000

min.non.empty.fraction = 0.9
tick.interval = 100
stats.interval = 100
out.dir = "output"
job.name = "msb"
if (Sys.getenv('OS')=="Windows_NT") {Sys.setlocale("LC_TIME", "English")} # used to get a month name in english
job.id = strftime(Sys.time(), format="%Y_%b_%d_%H_%M_%S")
file.ext = ".csv"
output.fname = paste(out.dir,"/",job.name,"_",job.id,file.ext, sep="")

args = commandArgs(T)
cat("Changing default parameters with command line arguments:\n")
for (arg in args) {
  cat(arg,"\n")
  eval(parse(text=arg))
}
