# 16S rRNA amplicon workflow for QIIME2, LEfSe, and Maaslin2

This repository provides a publication-ready 16S rRNA amplicon analysis workflow that mirrors the structure of the shotgun metagenomics repository as closely as possible.

## Workflow overview

```text
raw demultiplexed paired-end FASTQ
-> fastp quality control
-> QIIME2 import
-> DADA2 denoising
-> taxonomy assignment (SILVA classifier)
-> removal of chloroplast/mitochondria
-> rarefaction for diversity analyses
-> genus-level table export
-> LEfSe
-> Maaslin2
```

## Important assumptions

1. This workflow starts from **sample-level demultiplexed paired-end FASTQ files**.
2. Barcode demultiplexing is assumed to have already been completed by the sequencing provider or an upstream workflow.
3. The workflow follows your Methods description as closely as possible, but the exact barcode assignment/orientation-correction step is not explicitly implemented here because that requires raw multiplexed reads and platform-specific barcode metadata.
4. Rarefaction to 20,000 reads per sample is applied for diversity analysis outputs. Differential abundance workflows (LEfSe and Maaslin2) use the filtered feature table before rarefaction unless you intentionally replace the input.

## Repository structure

```text
16s_github_repo/
├── README.md
├── .gitignore
├── UPLOAD_CHECKLIST.md
├── metadata/
│   ├── manifest.tsv.example
│   └── sample_metadata.tsv.example
└── scripts/
    ├── 01_run_fastp.sh
    ├── 02_run_qiime2_dada2_taxonomy.sh
    ├── 03_export_taxa_tables.sh
    ├── 04_core_diversity.sh
    ├── 05_lefse_genus.R
    ├── 06_maaslin2_genus.R
    └── 07_run_all.sh
```

## Minimal files required for GitHub upload

### Core reproducibility files: **9 files**
1. `README.md`
2. `.gitignore`
3. `metadata/manifest.tsv.example`
4. `metadata/sample_metadata.tsv.example`
5. `scripts/01_run_fastp.sh`
6. `scripts/02_run_qiime2_dada2_taxonomy.sh`
7. `scripts/03_export_taxa_tables.sh`
8. `scripts/05_lefse_genus.R`
9. `scripts/06_maaslin2_genus.R`

### Optional convenience files
10. `scripts/04_core_diversity.sh`
11. `scripts/07_run_all.sh`
12. `UPLOAD_CHECKLIST.md`

## Input requirements

### 1. Raw demultiplexed paired-end FASTQ files
File naming examples:
- `Sample01_R1.fastq.gz` and `Sample01_R2.fastq.gz`
- `SRR000001_R1.fastq.gz` and `SRR000001_R2.fastq.gz`

### 2. QIIME2 manifest file
Prepare a tab-delimited manifest file like this:

```tsv
sample-id	forward-absolute-filepath	reverse-absolute-filepath
Sample01	/path/to/clean_fastq/Sample01_R1.clean.fastq.gz	/path/to/clean_fastq/Sample01_R2.clean.fastq.gz
Sample02	/path/to/clean_fastq/Sample02_R1.clean.fastq.gz	/path/to/clean_fastq/Sample02_R2.clean.fastq.gz
```

### 3. Sample metadata file
Prepare a tab-delimited metadata file like this:

```tsv
SampleID	Group
Sample01	NO
Sample02	YES
```

- `SampleID` must match the sample IDs used in the QIIME2 manifest.
- The current LEfSe script assumes a **two-group comparison**.
- The default reference group in the examples is `NO`.

## Software requirements

### Server-side
- Bash
- fastp
- QIIME2
- biom-format
- Python 3

### R-side
- data.table
- dplyr
- tibble
- stringr
- SummarizedExperiment
- S4Vectors
- lefser
- ggplot2
- Maaslin2

## Step 1. Quality control with fastp

```bash
bash scripts/01_run_fastp.sh \
  -i /path/to/raw_fastq \
  -o /path/to/clean_fastq \
  -t 8
```

Implemented QC rules:
- remove low-quality bases with mean quality < 20 in a 10-bp sliding window
- discard reads shorter than 50 bp after trimming
- discard reads containing N bases
- output cleaned paired FASTQ files and per-sample HTML/JSON reports

## Step 2. QIIME2 import, DADA2 denoising, taxonomy assignment

```bash
bash scripts/02_run_qiime2_dada2_taxonomy.sh \
  -m /path/to/manifest.tsv \
  -o /path/to/qiime2_results \
  -c /path/to/silva-138-2-classifier.qza \
  --trim-left-f 0 \
  --trim-left-r 0 \
  --trunc-len-f 240 \
  --trunc-len-r 220 \
  --sampling-depth 20000
```

Main outputs:
- `demux-paired-end.qza`
- `table-dada2.qza`
- `rep-seqs-dada2.qza`
- `denoising-stats.qza`
- `taxonomy.qza`
- `table-no-organelle.qza`
- `relative-frequency-table.qza`
- `table-no-organelle-rarefied-20000.qza`

## Step 3. Export taxa tables

```bash
bash scripts/03_export_taxa_tables.sh \
  -i /path/to/qiime2_results \
  -o /path/to/exported_tables
```

This script exports:
- ASV count table
- ASV taxonomy table
- genus-level count table
- genus-level relative abundance table
- family/phylum/... level tables (L2-L7)

## Step 4. Optional diversity analyses

```bash
bash scripts/04_core_diversity.sh \
  -i /path/to/qiime2_results \
  -m /path/to/sample_metadata.tsv \
  -o /path/to/diversity_results \
  --sampling-depth 20000
```

This script runs `qiime diversity core-metrics-phylogenetic` using the rarefied table.

## Step 5. LEfSe on genus relative abundance table

```bash
Rscript scripts/05_lefse_genus.R \
  --input-abundance /path/to/exported_tables/genus_relative_abundance.tsv \
  --group-file /path/to/sample_metadata.tsv \
  --outdir /path/to/results/lefse_genus \
  --sample-column SampleID \
  --group-column Group \
  --ref-level NO \
  --case-level YES
```

## Step 6. Maaslin2 on genus relative abundance table

```bash
Rscript scripts/06_maaslin2_genus.R \
  --input-abundance /path/to/exported_tables/genus_relative_abundance.tsv \
  --group-file /path/to/sample_metadata.tsv \
  --outdir /path/to/results/maaslin2_genus \
  --sample-column SampleID \
  --group-column Group \
  --reference-level NO \
  --q-cutoff 0.2
```

## One-command convenience runner

Edit variables in:

```bash
bash scripts/07_run_all.sh
```

## Notes for manuscript consistency

This repository matches a 16S workflow that uses:
- fastp for read QC
- QIIME2 DADA2 for denoising and ASV generation
- SILVA for taxonomy assignment
- chloroplast and mitochondria removal
- rarefaction to 20,000 reads/sample for diversity analyses
- genus-level exported table for LEfSe and Maaslin2

If your manuscript says the reads were merged with FLASH before DADA2, be cautious: the standard QIIME2 DADA2 paired-end workflow denoises paired reads directly and performs overlap-aware merging internally. The scripts here therefore use the standard and reproducible QIIME2 DADA2 paired-end implementation rather than a separate FLASH merge before DADA2.
