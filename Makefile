batch:
	sbatch c.job
	sbatch jl.job

.PHONE: clean

clean:
	rm *.out *.err stream
