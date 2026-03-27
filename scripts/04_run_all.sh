#!/usr/bin/env bash
set -euo pipefail

# Edit these paths before running
RAW_DIR="/path/to/raw_fastq"
CLEAN_DIR="/path/to/clean_fastq"
MANIFEST="/path/to/manifest.tsv"
METADATA="/path/to/sample_metadata.tsv"
CLASSIFIER="/path/to/silva-138-2-classifier.qza"
QIIME2_OUT="/path/to/qiime2_results"
EXPORT_DIR="/path/to/exports"
RESULT_DIR="/path/to/results"
THREADS=8
TRIM_LEFT_F=0
TRIM_LEFT_R=0
TRUNC_LEN_F=240
TRUNC_LEN_R=220
SAMPLING_DEPTH=20000

bash scripts/01_run_fastp.sh \
  -i "$RAW_DIR" \
  -o "$CLEAN_DIR" \
  -t "$THREADS"

bash scripts/02_run_qiime2_dada2_taxonomy.sh \
  -m "$MANIFEST" \
  -o "$QIIME2_OUT" \
  -c "$CLASSIFIER" \
  --trim-left-f "$TRIM_LEFT_F" \
  --trim-left-r "$TRIM_LEFT_R" \
  --trunc-len-f "$TRUNC_LEN_F" \
  --trunc-len-r "$TRUNC_LEN_R" \
  --sampling-depth "$SAMPLING_DEPTH"

bash scripts/03_export_taxa_tables.sh \
  -i "$QIIME2_OUT" \
  -o "$EXPORT_DIR"

echo "[INFO] Entire 16S workflow finished."
