debug = TRUE 

num.loci = 1000
num.alleles = 2
pop.size = 100000
s = 0.01
mu.rate = 0.003
rec.rate = 0.003
max.tick = 100000

min.non.empty.fraction = 0.9
tick.interval = 100
stats.interval = 100

job.name = "msb"
if (Sys.getenv('OS')=="Windows_NT") {Sys.setlocale("LC_TIME", "English")} # used to get a month name in english
job.id = strftime(Sys.time(), format="%Y_%b_%d_%H_%M_%S")

out.dir = "output"
output.ext = ".csv"
output.fname = paste(out.dir,"/", job.name,"_", job.id, output.ext, sep="")

ser.dir = "serialization"
ser.ext = ".RData"
ser.fname = paste(ser.dir, "/", job.name, "_", job.id, ser.ext, sep="")

start.model = "" #msb_2012_Nov_08_14_20_19"
start.fname = paste(ser.dir, "/", start.model, ser.ext, sep="")


args = commandArgs(T)
cat("Changing default parameters with command line arguments:\n")
for (arg in args) {
  cat(arg,"\n")
  eval(parse(text=arg))
}
