#!/bin/bash
REP=100
for rho in 1 1000000000 10000000000 100000000000
do
	for phi in 0 1000
	do
		for pi in 0 1
		do
			qsub -t 1-$REP -v r=0.00000000000003 -v in_pi=$pi -v in_tau=5 -v in_phi=$phi -v in_rho=$rho simulation.sge
			
		done
		qsub -t 1-$REP -v r=0.00000000000003 -v in_pi=1000 -v in_tau=1 -v in_phi=$phi -v in_rho=$rho simulation.sge
	done
done
