#!/bin/bash
REP=100
for pop_size in 100000 1000000 10000000
do
	for r in 0 0.00003 0.0003 0.003
	do
		for phi in 0 1000
		do
			for pi in 0 1
			do			
				for tau in 2 5 10
				do			
					qsub -t 1-$REP -v pop_size=$pop_size -v r=$r -v in_pi=$pi -v in_tau=$tau -v in_phi=$phi -v in_rho=10 simulation.sge
				done
			done
			qsub -t 1-$REP -v pop_size=$pop_size -v r=$r -v in_pi=1000 -v in_tau=1 -v in_phi=$phi -v in_rho=10 simulation.sge
		done
	done
done
