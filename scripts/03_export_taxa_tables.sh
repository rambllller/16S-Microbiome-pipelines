#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  bash scripts/03_export_taxa_tables.sh -i QIIME2_OUTDIR -o EXPORT_DIR

Required:
  -i  Directory containing QIIME2 outputs from script 02
  -o  Output directory for exported TSV tables
USAGE
}

while getopts ":i:o:h" opt; do
  case $opt in
    i) INPUT_DIR="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG"; usage; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument."; usage; exit 1 ;;
  esac
done

if [[ -z "${INPUT_DIR:-}" || -z "${OUTPUT_DIR:-}" ]]; then
  usage
  exit 1
fi

mkdir -p "$OUTPUT_DIR" "$OUTPUT_DIR/tmp"

# export ASV table
qiime tools export \
  --input-path "$INPUT_DIR/table-no-organelle.qza" \
  --output-path "$OUTPUT_DIR/tmp/asv_table"
biom convert \
  -i "$OUTPUT_DIR/tmp/asv_table/feature-table.biom" \
  -o "$OUTPUT_DIR/asv_counts.tsv" \
  --to-tsv

# export taxonomy
qiime tools export \
  --input-path "$INPUT_DIR/taxonomy.qza" \
  --output-path "$OUTPUT_DIR/tmp/taxonomy"
cp "$OUTPUT_DIR/tmp/taxonomy/taxonomy.tsv" "$OUTPUT_DIR/asv_taxonomy.tsv"

# export L2-L7 count and relative abundance tables
for level in 2 3 4 5 6 7; do
  qiime taxa collapse \
    --i-table "$INPUT_DIR/table-no-organelle.qza" \
    --i-taxonomy "$INPUT_DIR/taxonomy.qza" \
    --p-level "$level" \
    --o-collapsed-table "$OUTPUT_DIR/tmp/l${level}_counts.qza"

  qiime feature-table relative-frequency \
    --i-table "$OUTPUT_DIR/tmp/l${level}_counts.qza" \
    --o-relative-frequency-table "$OUTPUT_DIR/tmp/l${level}_relative.qza"

  qiime tools export \
    --input-path "$OUTPUT_DIR/tmp/l${level}_counts.qza" \
    --output-path "$OUTPUT_DIR/tmp/l${level}_counts"
  biom convert \
    -i "$OUTPUT_DIR/tmp/l${level}_counts/feature-table.biom" \
    -o "$OUTPUT_DIR/l${level}_counts.tsv" \
    --to-tsv

  qiime tools export \
    --input-path "$OUTPUT_DIR/tmp/l${level}_relative.qza" \
    --output-path "$OUTPUT_DIR/tmp/l${level}_relative"
  biom convert \
    -i "$OUTPUT_DIR/tmp/l${level}_relative/feature-table.biom" \
    -o "$OUTPUT_DIR/l${level}_relative_abundance.tsv" \
    --to-tsv

done

cp "$OUTPUT_DIR/l6_counts.tsv" "$OUTPUT_DIR/genus_counts.tsv"
cp "$OUTPUT_DIR/l6_relative_abundance.tsv" "$OUTPUT_DIR/genus_relative_abundance.tsv"

rm -rf "$OUTPUT_DIR/tmp"
echo "[INFO] Export of ASV and taxa tables finished. Outputs in: $OUTPUT_DIR"
