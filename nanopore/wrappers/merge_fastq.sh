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
LOWER_FASTQ_DIR_NUM=0
UPPER_FASTQ_DIR_NUM=-1

USAGE="$( basename $BASH_SOURCE )  [-h] [-b|--barcoding] [-l|--lower_fastq_dir_num] [-u|--upper_fastq_dir_num] -i|--input <inputdir>"

if [[ $# -eq 0 || $1 == "--help" ||  $1 == "-h" ]] 
then 
  echo "Usage: ${USAGE}"
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
    -l|--lower_fastq_dir_num)
    LOWER_FASTQ_DIR_NUM="$2"
    shift # past argument
    shift # past value
    ;;
    -u|--upper_fastq_dir_num)
    UPPER_FASTQ_DIR_NUM="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1")
    shift # past argument
    ;;
  esac
done

if [[ "${UPPER_FASTQ_DIR_NUM:-}" > -1 && "${LOWER_FASTQ_DIR_NUM}" > "${UPPER_FASTQ_DIR_NUM}" ]];
then
    echo "ERROR: Upper fastq dir must be greater than or equal to Lower fastq dir."
    exit 1
fi

NUM_FASTQ_SUBDIRS=$( ls -1 "$INPUT"/fastq | wc -l )

if [[ "${UPPER_FASTQ_DIR_NUM:-}" == -1 ]];
then
    UPPER_FASTQ_DIR_NUM=$(( $NUM_FASTQ_SUBDIRS - 1 ))
fi

(>&2 echo BARCODING = "${BARCODING}")
(>&2 echo LOWER_FASTQ_DIR_NUM  = "${LOWER_FASTQ_DIR_NUM}" )
(>&2 echo UPPER_FASTQ_DIR_NUM  = "${UPPER_FASTQ_DIR_NUM}" )
(>&2 echo QSUB_ERROR_LOG_DIR  = "${QSUB_ERROR_LOG_DIR}" )
(>&2 echo QSUB_OUTPUT_LOG_DIR = "${QSUB_OUTPUT_LOG_DIR}" )

# Prepare log dirs
mkdir -p "${QSUB_ERROR_LOG_DIR}"
mkdir -p "${QSUB_OUTPUT_LOG_DIR}"

if [ "$BARCODING" = false ]; then
  qsub -o "${QSUB_OUTPUT_LOG_DIR}" -e "${QSUB_ERROR_LOG_DIR}" "${MERGE_FASTQ_QSUB_SCRIPT}" "${INPUT}" -l "${LOWER_FASTQ_DIR_NUM}" -u "${UPPER_FASTQ_DIR_NUM}" --pass;
  qsub -o "${QSUB_OUTPUT_LOG_DIR}" -e "${QSUB_ERROR_LOG_DIR}" "${MERGE_FASTQ_QSUB_SCRIPT}" "${INPUT}" -l "${LOWER_FASTQ_DIR_NUM}" -u "${UPPER_FASTQ_DIR_NUM}" --fail
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
	qsub -o "${QSUB_OUTPUT_LOG_DIR}" -e "${QSUB_ERROR_LOG_DIR}" "${MERGE_FASTQ_QSUB_SCRIPT}" -i "${INPUT}" --barcode_id "$BARCODE_ID" -l "${LOWER_FASTQ_DIR_NUM}" -u "${UPPER_FASTQ_DIR_NUM}" --pass;
	qsub -o "${QSUB_OUTPUT_LOG_DIR}" -e "${QSUB_ERROR_LOG_DIR}" "${MERGE_FASTQ_QSUB_SCRIPT}" -i "${INPUT}" --barcode_id "$BARCODE_ID" -l "${LOWER_FASTQ_DIR_NUM}" -u "${UPPER_FASTQ_DIR_NUM}" --fail
    done
fi

