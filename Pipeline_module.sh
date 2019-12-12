#$ -l h_vmem=1G  # amount of memory
#$ -pe parallel 12 # number of core needed
#$ -S /bin/bash
#$ -cwd
#$ -e $JOB_NAME.$JOB_ID.ER # where to write stderr
#$ -o $JOB_NAME.$JOB_ID.OU # where to write stdout


DIR=/home/panpan/ATLINE1_2
DB=/home/panpan/ATLINE1_2
file=$file
FQ1=$file
FQ2=$(echo $file | sed -e "s/R1/R2/")
out=$(echo $file | awk -F "/" '{split($6,a,"_");print a[1]}')
te=$(echo $DB | awk -F "/" '{print $6}')

#travail en local sur le cluster
mkdir /tmp/tmp-$out
cd /tmp/tmp-$out
#copie des fichiers
cp $FQ1 .
cp $FQ2 .
cp $DB* .

fq1=$(echo $FQ1 | awk -F "/" '{print $6}')
fq2=$(echo $FQ2 | awk -F "/" '{print $6}')

#bowtie2-build tos17.fa tos17

#alignement des reads contre le TE
/usr/local/bowtie2-2.0.5/bowtie2 --time --end-to-end  -k 1 --very-fast -p 3 $te -1 $fq1 -2 $fq2 -S "$out"-vs-"$te".sam

#recuperation que des unmap flaggés unmap/map
#et création d'un fasta
awk -F "\t" '{if ( ($1!~/^@/) && (($2==69) || ($2==133) || ($2==165) || ($2==181) || ($2==101) || ($2==117)) ) {print ">"$1"\n"$10}}' $out-vs-$te.sam > $out-vs-$te.fa

#blast fa contre IRGSP1.0 pour identification point insertion
/usr/local/ncbi-blast-2.2.26+/bin/blastn -db /home/database/TAIR10/TAIR10_all_ssCM.fa -query $out-vs-$te.fa -out $out-vs-$te.fa.bl -num_threads 3 -evalue 1e-20

#parse blast pour récuperer point insertion
perl /home/mchristine/FRoux/trouver_position_insertion_tos.pl $out-vs-$te.fa.bl $out-vs-$te

#instersect avec IRGSP_windows_1kb
sort -k1,1 -k2,2n $out-vs-$te.bed > $out-vs-$te.sort.bed

#coveragebed cov 10
bedtools coverage -counts -a $out-vs-$te.sort.bed -b /home/database/TAIR10/TAIR10_10kbwindows.bed | awk -F "\t" '{if ($4>=10){print $0}}' > coveragebed_$out-vs-$te\_per10kb.bed

mv coveragebed_$out-vs-$te\_per10kb.bed $DIR
mv $out-vs-$te.sort.bed $DIR

#petit ménage
rm $out-vs-$te.sam
rm $out-vs-$te.fa*
rm $out-vs-$te.bed
rm *fastq
rm $te*
rm -r /tmp/tmp-$out

