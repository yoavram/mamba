debug = TRUE 

num.loci = 1000
num.alleles = 2
pop.size = 100000
s = 0.01
mu.rate = 0.003
rec.rate = 0.0
max.tick = 1000
env.change.freq = 0 #1/100
num.loci.to.change = 4

min.non.empty.fraction = 0.9
tick.interval = 100
stats.interval = 100
phylogeny = FALSE                                    

job.name = "msb"
if (Sys.getenv('OS')=="Windows_NT") {Sys.setlocale("LC_TIME", "English")} # used to get a month name in english
job.id = strftime(Sys.time(), format="%Y_%b_%d_%H_%M_%S")

log.dir = "log"
log.ext = ".log"
log.fname = paste(log.dir,"/", job.name,"_", job.id, log.ext, sep="")

out.dir = "output"
output.ext = ".csv"
output.fname = paste(out.dir,"/", job.name,"_", job.id, output.ext, sep="")

tree.dir = "trees"
tree.ext = ".RData"
tree.fname = paste(tree.dir,"/", job.name,"_", job.id, tree.ext, sep="")

ser.dir = "serialization"
ser.ext = ".RData"
ser.fname = paste(ser.dir, "/", job.name, "_", job.id, ser.ext, sep="")

start.model = "" #msb_2012_Nov_09_10_01_34" 
start.fname = paste(ser.dir, "/", start.model, ser.ext, sep="")

invasion.rate = 0.5
invader = c(pi=0, tau=10, phi=Inf, rho=1)

args = commandArgs(T)
cat("Changing default parameters with command line arguments:\n")
for (arg in args) {
  cat(arg,"\n")
  eval(parse(text=arg))
}
rm(arg)

if (debug) {
  max.tick <- 10
  num.loci <- 5
}

params <- ls.str()
