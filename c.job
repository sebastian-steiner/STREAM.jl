#! /bin/bash
#SBATCH -p q_thesis
#SBATCH -N 1
#SBATCH -c 32
#SBATCH --cpu-freq=High
#SBATCH --time=15:00
#SBATCH --output c.out
#SBATCH --error c.err

export OMP_NUM_THREADS=32

srun gcc -mcmodel=medium -fopenmp -O3 -DSTREAM_ARRAY_SIZE=1000000000 -DNTIMES=100 -o stream stream.c
srun likwid-pin -c N:0-31 ./stream
