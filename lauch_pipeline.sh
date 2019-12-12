#!/bin/bash

cd /home/panpan/ATLINE1_2

FASTQ=$(ls /home/panpan/rawdata/*R1.fastq)

for file in $FASTQ

do
qsub -v file=$file /home/panpan/Pipeline_module.sh
done
