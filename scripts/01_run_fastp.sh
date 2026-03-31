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

Supported input filename patterns:
  1) sample_R1.fastq.gz / sample_R2.fastq.gz
  2) sample_R1.fq.gz    / sample_R2.fq.gz
  3) sample_R1.fastq    / sample_R2.fastq
  4) sample_R1.fq       / sample_R2.fq
  5) sample.R1.raw.fastq.gz / sample.R2.raw.fastq.gz
  6) sample.R1.raw.fq.gz    / sample.R2.raw.fq.gz
  7) sample.R1.raw.fastq    / sample.R2.raw.fastq
  8) sample.R1.raw.fq       / sample.R2.raw.fq
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

if ! command -v fastp >/dev/null 2>&1; then
  echo "[ERROR] fastp not found in PATH. Please activate the correct environment first."
  exit 1
fi

mkdir -p "$OUTPUT_DIR" "$OUTPUT_DIR/reports"
shopt -s nullglob

mapfile -t r1_files < <(find "$INPUT_DIR" -maxdepth 1 -type f \( \
  -name "*_R1.fastq.gz" -o -name "*_R1.fq.gz" -o -name "*_R1.fastq" -o -name "*_R1.fq" -o \
  -name "*.R1.raw.fastq.gz" -o -name "*.R1.raw.fq.gz" -o -name "*.R1.raw.fastq" -o -name "*.R1.raw.fq" \
\) | sort)

if [[ ${#r1_files[@]} -eq 0 ]]; then
  echo "No supported R1 FASTQ files found in: $INPUT_DIR"
  echo "Supported examples: sample_R1.fastq.gz or sample.R1.raw.fastq.gz"
  exit 1
fi

get_sample_and_r2() {
  local r1_base="$1"
  local sample=""
  local r2=""

  case "$r1_base" in
    *_R1.fastq.gz)
      sample="${r1_base%%_R1.fastq.gz}"
      r2="$INPUT_DIR/${sample}_R2.fastq.gz"
      ;;
    *_R1.fq.gz)
      sample="${r1_base%%_R1.fq.gz}"
      r2="$INPUT_DIR/${sample}_R2.fq.gz"
      ;;
    *_R1.fastq)
      sample="${r1_base%%_R1.fastq}"
      r2="$INPUT_DIR/${sample}_R2.fastq"
      ;;
    *_R1.fq)
      sample="${r1_base%%_R1.fq}"
      r2="$INPUT_DIR/${sample}_R2.fq"
      ;;
    *.R1.raw.fastq.gz)
      sample="${r1_base%%.R1.raw.fastq.gz}"
      r2="$INPUT_DIR/${sample}.R2.raw.fastq.gz"
      ;;
    *.R1.raw.fq.gz)
      sample="${r1_base%%.R1.raw.fq.gz}"
      r2="$INPUT_DIR/${sample}.R2.raw.fq.gz"
      ;;
    *.R1.raw.fastq)
      sample="${r1_base%%.R1.raw.fastq}"
      r2="$INPUT_DIR/${sample}.R2.raw.fastq"
      ;;
    *.R1.raw.fq)
      sample="${r1_base%%.R1.raw.fq}"
      r2="$INPUT_DIR/${sample}.R2.raw.fq"
      ;;
    *)
      return 1
      ;;
  esac

  printf '%s\t%s\n' "$sample" "$r2"
}

processed=0
skipped=0

for r1 in "${r1_files[@]}"; do
  base=$(basename "$r1")

  if ! parsed=$(get_sample_and_r2 "$base"); then
    echo "[WARN] Unrecognized R1 filename pattern: $base. Skipping."
    ((skipped+=1))
    continue
  fi

  sample=${parsed%%$'\t'*}
  r2=${parsed#*$'\t'}

  if [[ ! -f "$r2" ]]; then
    echo "[WARN] Missing matching R2 for sample: $sample"
    echo "       Expected: $r2"
    ((skipped+=1))
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

  ((processed+=1))
done

echo "[INFO] fastp QC finished. Processed: $processed | Skipped: $skipped"
echo "[INFO] Clean reads in: $OUTPUT_DIR"
