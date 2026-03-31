# 16S rRNA amplicon workflow for QIIME2-based taxonomic profiling

This repository provides a publication-ready 16S rRNA amplicon analysis workflow that mirrors the structure of the shotgun metagenomics repository as closely as possible.

## Workflow overview

```text
raw demultiplexed paired-end FASTQ

\-> fastp quality control

\-> QIIME2 import

\-> DADA2 denoising

\-> taxonomy assignment (SILVA classifier)

\-> removal of chloroplast/mitochondria

\-> genus-level table export

```

## Repository structure

```text
16s\_github\_repo/
├── README.md
├── .gitignore
├── UPLOAD\_CHECKLIST.md
├── metadata/
│   ├── manifest.tsv.example
│   └── sample\_metadata.tsv.example
└── scripts/
    ├── 01\_run\_fastp.sh
    ├── 02\_run\_qiime2\_dada2\_taxonomy.sh
    ├── 03\_export\_taxa\_tables.sh
    └── 04\_run\_all.sh
```

## Input requirements

### 1\. Raw demultiplexed paired-end FASTQ files

File naming examples:

* `Sample01\_R1.raw.fastq.gz` and `Sample01\_R2.raw.fastq.gz`
* `SRR000001\_R1.fastq.gz` and `SRR000001\_R2.fastq.gz`

### 2\. QIIME2 manifest file

Prepare a tab-delimited manifest file like this:

```tsv
sample-id	forward-absolute-filepath	reverse-absolute-filepath
Sample01	/path/to/clean\_fastq/Sample01\_R1.clean.fastq.gz	/path/to/clean\_fastq/Sample01\_R2.clean.fastq.gz
Sample02	/path/to/clean\_fastq/Sample02\_R1.clean.fastq.gz	/path/to/clean\_fastq/Sample02\_R2.clean.fastq.gz
```

## Software requirements

### Server-side

* Bash
* fastp
* QIIME2
* biom-format
* Python 3

## Step 1. Quality control with fastp

```bash
bash scripts/01\_run\_fastp.sh \\
  -i /path/to/raw\_fastq \\
  -o /path/to/clean\_fastq \\
  -t 8
```

Implemented QC rules:

* remove low-quality bases with mean quality < 20 in a 10-bp sliding window
* discard reads shorter than 50 bp after trimming
* discard reads containing N bases
* output cleaned paired FASTQ files and per-sample HTML/JSON reports

## Step 2. QIIME2 import, DADA2 denoising, taxonomy assignment

```bash
bash scripts/02\_run\_qiime2\_dada2\_taxonomy.sh \\
  -m /path/to/manifest.tsv \\
  -o /path/to/qiime2\_results \\
  -c /path/to/silva-138-2-classifier.qza \\
  --trim-left-f 0 \\
  --trim-left-r 0 \\
  --trunc-len-f 240 \\
  --trunc-len-r 220
```

Main outputs:

* `demux-paired-end.qza`
* `table-dada2.qza`
* `rep-seqs-dada2.qza`
* `denoising-stats.qza`
* `taxonomy.qza`
* `table-no-organelle.qza`
* `relative-frequency-table.qza`

## Step 3. Export taxa tables

```bash
bash scripts/03\_export\_taxa\_tables.sh \\
  -i /path/to/qiime2\_results \\
  -o /path/to/exported\_tables
```

This script exports:

* ASV count table
* ASV taxonomy table
* genus-level count table
* genus-level relative abundance table
* family/phylum/... level tables (L2-L7)

## One-command convenience runner

Edit variables in:

```bash
bash scripts/04\_run\_all.sh
```

## Notes for manuscript consistency

This repository matches a 16S workflow that uses:

* fastp for read QC
* QIIME2 DADA2 for denoising and ASV generation
* SILVA for taxonomy assignment
* chloroplast and mitochondria removal
* genus-level and other rank-level relative abundance tables

