#!/bin/bash
REP=100
R=0.1

for pop_size in 100 500 1000
do
	for BETA in 0 0.1
	do
		qsub -N shaw2011 -t 1-$REP -v mu=0.1 -v s=0.02 -v pop_size=$pop_size -v r=$R -v beta=$BETA -v pi=0 -v tau=1 msdb.sge
                qsub -N shaw2011 -t 1-$REP -v mu=0.1 -v s=0.02 -v pop_size=$pop_size -v r=$R -v beta=$BETA -v pi=0 -v tau=4 msdb.sge
                qsub -N shaw2011 -t 1-$REP -v mu=0.1 -v s=0.02 -v pop_size=$pop_size -v r=$R -v beta=$BETA -v pi=1 -v tau=4 msdb.sge
                #qsub -N shaw2011 -t 1-$REP -v mu=0.1 -v s=0.02 -v pop_size=$pop_size -v r=$R -v beta=$BETA -v pi=2 -v tau=4 msdb.sge
	done
done
