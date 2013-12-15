#!/bin/bash
REP=100
for r in 0.0 0.00003 0.003 0.03 
do
	for pi in 0 1 1000
	do
		for phi in 1000
		do
			for tau in 2 5 10 100
			do			
				qsub -t 1-$REP -v in_pi=$pi -v in_tau=$tau -v r=$r -v in_phi=$phi -v in_rho=$tau simulation.sge
			done
		done
	done
done
