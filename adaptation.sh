#!/bin/bash
REP=100
for r in 0.0 0.00003 0.003 0.03 
do
	for pi in 0 1 1000
	do
		for phi in 1000
		do
			for tau in 2 5 10
			do			
				qsub -t 1-$REP -v pi=$pi -v tau=$tau -v r=$r -v phi=$phi -v rho=$tau adaptation.sge
			done
		done
	done
done
