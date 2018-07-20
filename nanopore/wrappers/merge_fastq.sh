#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Constants
declare -r MERGE_FASTQ_QSUB_SCRIPT="/home/dfornika/code/qsub-scripts/nanopore/merge_fastq.qsub" # replace when we decide on a system-wide install location
declare -r QSUB_ERROR_LOG_DIR="/data/minion/basecalls/qsub_logs/$( date --iso-8601 )/merge_fastq"
declare -r QSUB_OUTPUT_LOG_DIR="/data/minion/basecalls/qsub_logs/$( date --iso-8601 )/merge_fastq"

# Defaults
BARCODING=false
BARCODE_IDS=()

USAGE=$'$(basename "$0") [-h] [-b|--barcoding] -i|--input <inputdir>'

if [[ $# -eq 0 || $1 == "--help" ||  $1 == "-h" ]] 
then 
  echo "${USAGE}"
  exit 0
fi

while [[ $# -gt 0 ]]
do
  key="$1"
  
  case $key in
    -i|--input)
    # Base directory for run (must contain a 'fastq' subdir)
    INPUT="$2"
    shift # past argument
    shift # past value
    ;;
    -b|--barcoding)
    # No value, just the argument
    BARCODING=true
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1")
    shift # past argument
    ;;
  esac
done

(>&2 echo BARCODING = "${BARCODING}")
(>&2 echo QSUB_ERROR_LOG_DIR  = "${QSUB_ERROR_LOG_DIR}" )
(>&2 echo QSUB_OUTPUT_LOG_DIR = "${QSUB_OUTPUT_LOG_DIR}" )

# Prepare log dirs
mkdir -p "${QSUB_ERROR_LOG_DIR}"
mkdir -p "${QSUB_OUTPUT_LOG_DIR}"

if [ "$BARCODING" = false ]; then
  qsub -o "${QSUB_OUTPUT_LOG_DIR}" -e "${QSUB_ERROR_LOG_DIR}" "${MERGE_FASTQ_QSUB_SCRIPT}" "${INPUT}" --pass;
  qsub -o "${QSUB_OUTPUT_LOG_DIR}" -e "${QSUB_ERROR_LOG_DIR}" "${MERGE_FASTQ_QSUB_SCRIPT}" "${INPUT}" --fail
elif [ "$BARCODING" = true ]; then
    # Enumerate all barcode IDs 
    for FASTQ_SUBDIR in $( ls -1 "${INPUT}/fastq" ); do
	for BARCODE_ID in $( ls -1 "${INPUT}"/fastq/"${FASTQ_SUBDIR}"/workspace/pass; ls -1 "${INPUT}"/fastq/"${FASTQ_SUBDIR}"/workspace/fail ); do
	    if [[ ! " ${BARCODE_IDS[@]-} " =~ " ${BARCODE_ID} " ]]; then
		BARCODE_IDS+=("${BARCODE_ID}")
	    fi
	done
    done

    # Submit qsub jobs
    for BARCODE_ID in "${BARCODE_IDS[@]}"; do
	qsub -o "${QSUB_OUTPUT_LOG_DIR}" -e "${QSUB_ERROR_LOG_DIR}" "${MERGE_FASTQ_QSUB_SCRIPT}" -i "${INPUT}" --barcode_id "$BARCODE_ID" --pass;
	qsub -o "${QSUB_OUTPUT_LOG_DIR}" -e "${QSUB_ERROR_LOG_DIR}" "${MERGE_FASTQ_QSUB_SCRIPT}" -i "${INPUT}" --barcode_id "$BARCODE_ID" --fail
    done
fi

