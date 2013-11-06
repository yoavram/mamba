#!/bin/bash
REP=100
for pop_size in 100 500 1000
do
	for r in 0 0.003
	do
		qsub -t 1-$REP -v pop_size=$pop_size -v pi=0 -v tau=1 -v r=$r msdb.sge
                qsub -t 1-$REP -v pop_size=$pop_size -v pi=0 -v tau=4 -v r=$r msdb.sge
                qsub -t 1-$REP -v pop_size=$pop_size -v pi=1 -v tau=4 -v r=$r msdb.sge
                qsub -t 1-$REP -v pop_size=$pop_size -v pi=2 -v tau=4 -v r=$r msdb.sge
	done
done
