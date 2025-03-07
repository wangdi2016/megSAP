#!/bin/bash

set -e
set -o pipefail
set -o verbose

if [ -z "$1" ]
  then
    data_folder=`pwd`
  else
    data_folder=$1
fi

#download reference data for gene expression
cd $data_folder
mkdir -p dbs/gene_expression
cd dbs/gene_expression
#change version number on update
wget -O - https://www.proteinatlas.org/download/rna_tissue_consensus.tsv.zip | gunzip > rna_tissue_consensus_v22.tsv

#download Ensembl data in GTF format
cd $data_folder
mkdir -p dbs/gene_annotations
wget -O - 'https://ftp.ensembl.org/pub/release-109/gtf/homo_sapiens/Homo_sapiens.GRCh38.109.gtf.gz' | \
  gzip -cd | \
  awk '{ if ($1 !~ /^#/) { print "chr"$0 } else { print $0 } }' > dbs/gene_annotations/GRCh38.gtf

#STAR: index genome
cd $data_folder
mkdir -p genomes/STAR/GRCh38
$data_folder/tools/STAR-2.7.10b/bin/Linux_x86_64/STAR \
--runThreadN 20 \
--runMode genomeGenerate \
--genomeDir genomes/STAR/GRCh38/ \
--genomeFastaFiles genomes/GRCh38.fa \
--sjdbGTFfile dbs/gene_annotations/GRCh38.gtf

#build kraken2 database
cd $data_folder
tools/kraken2-2.1.2/bin/kraken2-build -db dbs/kraken2_filter_hb --download-taxonomy --skip-map  --use-ftp
tools/kraken2-2.1.2/bin/kraken2-build -db dbs/kraken2_filter_hb --add-to-library $data_folder/misc/human_hemoglobin_tx.fa
tools/kraken2-2.1.2/bin/kraken2-build --build  --threads 5 --db dbs/kraken2_filter_hb
