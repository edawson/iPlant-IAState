## Makefile for IAState Livestock Genomics Pipeline
## (Allows faster prototyping of different software versions)
##
## Eric T Dawson
## Texas Advanced Computing Center
## January 2015

OLD_SAMTOOLS=samtools-0.1.19
NEW_SAMTOOLS=samtools-1.1
LATEST_BWA=bwa-0.7.12

BWA=$(LATEST_BWA)

run: samtools bwa picard

bwa:

samtools:

picard:
