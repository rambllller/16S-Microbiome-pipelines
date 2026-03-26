# Upload checklist for GitHub

## Upload these files
- README.md
- .gitignore
- metadata/manifest.tsv.example
- metadata/sample_metadata.tsv.example
- scripts/01_run_fastp.sh
- scripts/02_run_qiime2_dada2_taxonomy.sh
- scripts/03_export_taxa_tables.sh
- scripts/05_lefse_genus.R
- scripts/06_maaslin2_genus.R

## Optional but recommended
- scripts/04_core_diversity.sh
- scripts/07_run_all.sh
- UPLOAD_CHECKLIST.md

## Do NOT upload
- raw FASTQ files
- clean FASTQ files
- .qza / .qzv artifacts unless you intentionally want to share processed example data
- large HTML/JSON QC reports unless you intentionally want to share them
- absolute server paths containing private usernames or directories

## Before release
- confirm sample metadata column names
- confirm group labels in the manuscript and code are consistent
- record QIIME2 and classifier version in the manuscript
- record SILVA classifier file name used for taxonomy assignment
