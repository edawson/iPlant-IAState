#!/bin/bash
#SBATCH -J test_ias
#SBATCH -o ias_test.o%j
#SBATCH -A iPlant-Collabs
#SBATCH -p normal
#SBATCH -t 8:00:00
#SBATCH -N 1
#SBATCH -n 16


## /home/eric.fritz/bwa-0.7.5a/bwa mem -t 12 ~/christine/UMD31.fasta WHWT.86391.AP.03.1_Unique.fastq WHWT.86391.AP.03.2_Unique.fastq | ~/tophat2/samtools view -bhS - | ~/tophat2/samtools sort - WHWT.86391.AP.03.mem.sorted
#java1.7/bin/java -jar picard/AddOrReplaceReadGroups.jar INPUT=WHWT.86391.AP.03.mem.sorted.bam OUTPUT=WHWT.86391.AP.03.mem.fixed.bam RGLB=1 RGPL=illumina RGPU=all RGSM=WHWT.86391.AP.03 VALIDATION_STRINGENCY=SILENT
#tophat2/samtools index WHWT.86391.AP.03.mem.fixed.bam
#java1.7/bin/java -jar -Xmx48g GATK2.7/GenomeAnalysisTK.jar -R christine/UMD31.fasta -T UnifiedGenotyper -I WHWT.86391.AP.03.mem.fixed.bam -o WHWT.86391.AP.03.mem.vcf -dt NONE -allowPotentiallyMisencodedQuals

timestamp() {   date +"%H_%M_%S"; }

bwa=./bin/bwa
samtools=./bin/samtools
$bwa
$samtools

#module load java
module load gatk/2.7.2

gatk=${TACC_GATK_DIR}/GenomeAnalysisTK.jar

module load picard/1.83

picard=${TACC_PICARD_DIR}

data_a="WHWT.86391.AP.03.1_Unique.fastq"
data_b="WHWT.86391.AP.03.2_Unique.fastq"
ref=UMD31.fasta
x=`timestamp`
## BWA mem/aln
$bwa mem -t 16 $ref $data_a $data_b | $samtools view -bhS - | $samtools sort - WHWT.86391.AP.03.mem.$x.sorted

## Picard replace read group (perhaps possible via BASH or samtools)
java -jar ${picard}/AddOrReplaceReadGroups.jar INPUT=WHWT.86391.AP.03.mem.$x.sorted.bam OUTPUT=WHWT.86391.AP.03.mem.$x.fixed.bam RGLB=1 RGPL=illumina RGPU=all RGSM=WHWT.86391.AP.03 VALIDATION_STRINGENCY=SILENT

## Samtools index the bam
$samtools index WHWT.86391.AP.03.mem.$x.fixed.bam

## Use GATK Unified Genotyper
java -jar -Xmx20g $gatk -R UMD31.fasta -T UnifiedGenotyper -nct 16 -I WHWT.86391.AP.03.mem.$x.fixed.bam -o WHWT.86391.AP.03.mem.$x.vcf -dt NONE -allowPotentiallyMisencodedQuals

