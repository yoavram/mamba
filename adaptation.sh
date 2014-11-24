#!/bin/bash
REP=100
for pop_size in 10000 100000 1000000
do
	for r in 0 0.00003 0.0003 0.003
	do
		for pi in 0 1
		do			
			for tau in 2 5 10
			do			
				qsub -t 1-$REP -v pop_size=$pop_size -v pi=$pi -v tau=$tau -v r=$r adaptation.sge
			done
		done
		qsub -t 1-$REP -v pop_size=$pop_size -v pi=1000 -v tau=1 -v r=$r adaptation.sge
	done
done
