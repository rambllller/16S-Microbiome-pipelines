#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  bash scripts/02_run_qiime2_dada2_taxonomy.sh -m MANIFEST -o OUTDIR -c CLASSIFIER \
    [--trim-left-f 0] [--trim-left-r 0] [--trunc-len-f 240] [--trunc-len-r 220]

Required:
  -m  QIIME2 paired-end manifest TSV
  -o  Output directory for QIIME2 artifacts
  -c  Trained SILVA classifier (.qza)

Optional:
  --trim-left-f      Default 0
  --trim-left-r      Default 0
  --trunc-len-f      Default 240
  --trunc-len-r      Default 220
USAGE
}

TRIM_LEFT_F=0
TRIM_LEFT_R=0
TRUNC_LEN_F=240
TRUNC_LEN_R=220

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -m) MANIFEST="$2"; shift; shift ;;
    -o) OUTDIR="$2"; shift; shift ;;
    -c) CLASSIFIER="$2"; shift; shift ;;
    --trim-left-f) TRIM_LEFT_F="$2"; shift; shift ;;
    --trim-left-r) TRIM_LEFT_R="$2"; shift; shift ;;
    --trunc-len-f) TRUNC_LEN_F="$2"; shift; shift ;;
    --trunc-len-r) TRUNC_LEN_R="$2"; shift; shift ;;
    -h|--help) usage; exit 0 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done
set -- "${POSITIONAL[@]}"

if [[ -z "${MANIFEST:-}" || -z "${OUTDIR:-}" || -z "${CLASSIFIER:-}" ]]; then
  usage
  exit 1
fi

mkdir -p "$OUTDIR"

qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path "$MANIFEST" \
  --output-path "$OUTDIR/demux-paired-end.qza" \
  --input-format PairedEndFastqManifestPhred33V2

qiime demux summarize \
  --i-data "$OUTDIR/demux-paired-end.qza" \
  --o-visualization "$OUTDIR/demux-paired-end.qzv"

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs "$OUTDIR/demux-paired-end.qza" \
  --p-trim-left-f "$TRIM_LEFT_F" \
  --p-trim-left-r "$TRIM_LEFT_R" \
  --p-trunc-len-f "$TRUNC_LEN_F" \
  --p-trunc-len-r "$TRUNC_LEN_R" \
  --o-table "$OUTDIR/table-dada2.qza" \
  --o-representative-sequences "$OUTDIR/rep-seqs-dada2.qza" \
  --o-denoising-stats "$OUTDIR/denoising-stats.qza" \
  --o-base-transition-stats "$OUTDIR/base-transition-stats.qza"

qiime feature-table summarize \
  --i-table "$OUTDIR/table-dada2.qza" \
  --o-visualization "$OUTDIR/table-dada2.qzv"

qiime feature-table tabulate-seqs \
  --i-data "$OUTDIR/rep-seqs-dada2.qza" \
  --o-visualization "$OUTDIR/rep-seqs-dada2.qzv"

qiime metadata tabulate \
  --m-input-file "$OUTDIR/denoising-stats.qza" \
  --o-visualization "$OUTDIR/denoising-stats.qzv"

qiime feature-classifier classify-sklearn \
  --i-classifier "$CLASSIFIER" \
  --i-reads "$OUTDIR/rep-seqs-dada2.qza" \
  --o-classification "$OUTDIR/taxonomy.qza"

qiime metadata tabulate \
  --m-input-file "$OUTDIR/taxonomy.qza" \
  --o-visualization "$OUTDIR/taxonomy.qzv"

qiime taxa filter-table \
  --i-table "$OUTDIR/table-dada2.qza" \
  --i-taxonomy "$OUTDIR/taxonomy.qza" \
  --p-exclude mitochondria,chloroplast \
  --o-filtered-table "$OUTDIR/table-no-organelle.qza"

qiime taxa filter-seqs \
  --i-sequences "$OUTDIR/rep-seqs-dada2.qza" \
  --i-taxonomy "$OUTDIR/taxonomy.qza" \
  --p-exclude mitochondria,chloroplast \
  --o-filtered-sequences "$OUTDIR/rep-seqs-no-organelle.qza"

qiime feature-table summarize \
  --i-table "$OUTDIR/table-no-organelle.qza" \
  --o-visualization "$OUTDIR/table-no-organelle.qzv"

qiime feature-table relative-frequency \
  --i-table "$OUTDIR/table-no-organelle.qza" \
  --o-relative-frequency-table "$OUTDIR/relative-frequency-table.qza"

echo "[INFO] QIIME2 DADA2 + taxonomy pipeline finished. Outputs in: $OUTDIR"
