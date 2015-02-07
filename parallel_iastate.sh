#!/bin/bash
#SBATCH -J test_par
#SBATCH -o par_test.o%j
#SBATCH -A iPlant-Collabs
#SBATCH -p normal
#SBATCH -t 8:00:00
#SBATCH -N 1
#SBATCH -n 16


## /home/eric.fritz/bwa-0.7.5a/bwa mem -t 12 ~/christine/UMD31.fasta WHWT.86391.AP.03.1_Unique.fastq WHWT.86391.AP.03.2_Unique.fastq | ~/tophat2/samtools view -bhS - | ~/tophat2/samtools sort - WHWT.86391.AP.03.mem.sorted
#java1.7/bin/java -jar picard/AddOrReplaceReadGroups.jar INPUT=WHWT.86391.AP.03.mem.sorted.bam OUTPUT=WHWT.86391.AP.03.mem.fixed.bam RGLB=1 RGPL=illumina RGPU=all RGSM=WHWT.86391.AP.03 VALIDATION_STRINGENCY=SILENT
#tophat2/samtools index WHWT.86391.AP.03.mem.fixed.bam
#java1.7/bin/java -jar -Xmx48g GATK2.7/GenomeAnalysisTK.jar -R christine/UMD31.fasta -T UnifiedGenotyper -I WHWT.86391.AP.03.mem.fixed.bam -o WHWT.86391.AP.03.mem.vcf -dt NONE -allowPotentiallyMisencodedQuals

module load pylauncher

timestamp() {   date +"%H_%M_%S"; }

bwa=`pwd`/bin/bwa
samtools=`pwd`/bin/samtools
$bwa
$samtools

#module load java
module load gatk/2.7.2

gatk=${TACC_GATK_DIR}/GenomeAnalysisTK.jar

module load picard/1.83
# Create subdirectories for BWA workflow
for I in input1 input2 temp
do
    echo "Removing old $I"
    rm -rf $I
    echo "Creating $I"
    mkdir -p $I
done

date

picard=${TACC_PICARD_DIR}

data_a="WHWT.86391.AP.03.1_Unique.fastq"
data_b="WHWT.86391.AP.03.2_Unique.fastq"
ref=UMD31.fasta
x=`timestamp`
IS_PAIRED=1
SPLIT_COUNT=1000000

QUERY1_F=$(basename ${data_a})
if [[ "$QUERY1_F" =~ .fq$ ]] || [[ "$QUERY1_F" =~ .fastq$ ]] || [[ "$QUERY1_F" =~ .fasta$ ]] || [[ "$QUERY1_F" =~ .fa$ ]]; then
    split -l $SPLIT_COUNT -a 4 --numeric-suffixes $QUERY1_F input1/query.
    echo "$QUERY1_F was not compressed";
elif [[ "$QUERY1_F" =~ .gz$ ]]; then
    bin/extract.sh $QUERY1_F | split -l $SPLIT_COUNT --numeric-suffixes - input1/query.
    echo "$QUERY1_F was compressed";
fi

QUERY2_F=$(basename ${data_b})
if [[ "$QUERY2_F" =~ .fq$ ]] || [[ "$QUERY2_F" =~ .fastq$ ]] || [[ "$QUERY2_F" =~ .fasta$ ]] || [[ "$QUERY2_F" =~ .fa$ ]]; then
    split -l $SPLIT_COUNT -a 4 --numeric-suffixes $QUERY1_F input2/query.
    echo "$QUERY2_F was not compressed";
elif [[ "$QUERY2_F" =~ .gz$ ]]; then
    bin/extract.sh $QUERY2_F | split -l $SPLIT_COUNT --numeric-suffixes - input2/query.
    echo "$QUERY2_F was compressed";
fi



rm -rf paramlist.txt
## BWA mem/aln
    #$bwa mem -t 16 $ref $data_a $data_b | $samtools view -bhS - | $samtools sort - WHWT.86391.AP.03.mem.$x.sorted
for C in ./input1/*
do
    ROOT=$(basename $C)
    echo "$bwa mem -t 4 $ref input1/$ROOT input2/$ROOT | $samtools view -bhS - | $samtools sort - temp/$ROOT.mem.$x.sorted" >> paramlist.txt
done

python launcher.py paramlist.txt

OWD=$PWD
BAMS=""
for i in `ls ./temp/`
do
    BAMS+=" temp/${i}"
done
OUTPUT=WHWT.86391.AP.03.mem.$x.sorted.bam

$samtools merge $OWD/$OUTPUT ${BAMS} && $samtools index ${OWD}/${OUTPUT}

## Picard replace read group (perhaps possible via BASH or samtools)
java -jar ${picard}/AddOrReplaceReadGroups.jar INPUT=WHWT.86391.AP.03.mem.$x.sorted.bam OUTPUT=WHWT.86391.AP.03.mem.$x.fixed.bam RGLB=1 RGPL=illumina RGPU=all RGSM=WHWT.86391.AP.03 VALIDATION_STRINGENCY=SILENT

## Samtools index the bam
$samtools index WHWT.86391.AP.03.mem.$x.fixed.bam

## Use GATK Unified Genotyper
java -jar -Xmx20g $gatk -R UMD31.fasta -T UnifiedGenotyper -nct 16 -I WHWT.86391.AP.03.mem.$x.fixed.bam -o WHWT.86391.AP.03.mem.$x.vcf -dt NONE -allowPotentiallyMisencodedQuals

date
