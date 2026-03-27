#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  bash scripts/01_run_fastp.sh -i RAW_DIR -o CLEAN_DIR [-t THREADS]

Required:
  -i  Input directory containing demultiplexed paired-end FASTQ(.gz)
  -o  Output directory for cleaned FASTQ files and reports

Optional:
  -t  Threads per sample [default: 4]
USAGE
}

THREADS=4
while getopts ":i:o:t:h" opt; do
  case $opt in
    i) INPUT_DIR="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    t) THREADS="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG"; usage; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument."; usage; exit 1 ;;
  esac
done

if [[ -z "${INPUT_DIR:-}" || -z "${OUTPUT_DIR:-}" ]]; then
  usage
  exit 1
fi

mkdir -p "$OUTPUT_DIR" "$OUTPUT_DIR/reports"
shopt -s nullglob

mapfile -t r1_files < <(find "$INPUT_DIR" -maxdepth 1 -type f \( -name "*_R1.fastq.gz" -o -name "*_R1.fq.gz" -o -name "*_R1.fastq" -o -name "*_R1.fq" \) | sort)
if [[ ${#r1_files[@]} -eq 0 ]]; then
  echo "No R1 FASTQ files found in: $INPUT_DIR"
  exit 1
fi

for r1 in "${r1_files[@]}"; do
  base=$(basename "$r1")
  sample=${base%%_R1.fastq.gz}
  sample=${sample%%_R1.fq.gz}
  sample=${sample%%_R1.fastq}
  sample=${sample%%_R1.fq}

  r2=""
  for ext in fastq.gz fq.gz fastq fq; do
    candidate="$INPUT_DIR/${sample}_R2.${ext}"
    if [[ -f "$candidate" ]]; then
      r2="$candidate"
      break
    fi
  done

  if [[ -z "$r2" ]]; then
    echo "[WARN] Missing R2 for sample: $sample. Skipping."
    continue
  fi

  echo "[INFO] Running fastp for $sample"
  fastp \
    --in1 "$r1" \
    --in2 "$r2" \
    --out1 "$OUTPUT_DIR/${sample}_R1.clean.fastq.gz" \
    --out2 "$OUTPUT_DIR/${sample}_R2.clean.fastq.gz" \
    --qualified_quality_phred 20 \
    --cut_front \
    --cut_tail \
    --cut_window_size 10 \
    --cut_mean_quality 20 \
    --length_required 50 \
    --n_base_limit 0 \
    --detect_adapter_for_pe \
    --thread "$THREADS" \
    --html "$OUTPUT_DIR/reports/${sample}.fastp.html" \
    --json "$OUTPUT_DIR/reports/${sample}.fastp.json"
done

echo "[INFO] fastp QC finished. Clean reads in: $OUTPUT_DIR"
