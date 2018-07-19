#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Constants
declare -r NANOPOLISH_INDEX_QSUB_SCRIPT="/home/dfornika/code/qsub-scripts/nanopore/nanopolish_index.qsub" # replace when we decide on a system-wide install location

USAGE=$'$(basename "$0") [-h] -5|--fast5 FAST5_DIR -q|--fastq MERGED_FASTQ_DIR'

if [[ $# -eq 0 || $1 == "--help" ||  $1 == "-h" ]] 
then 
  echo "${USAGE}"
  exit 0
fi

while [[ $# -gt 0 ]]
do
  key="$1"
  
  case $key in
    -5|--fast5)
    # raw_signal directory for run (must contain a 'fast5' subdir)
    FAST5_DIR="$2"
    shift # past argument
    shift # past value
    ;;
    -q|--fastq)
    # Directory containing merged fastq files
    FASTQ_DIR="$2"
    shift # past argument
    shift # past value
    ;;
  esac
done

# Submit qsub jobs
for FASTQ in $( find "${FASTQ_DIR}" -type f ); do
    qsub "${NANOPOLISH_INDEX_QSUB_SCRIPT}" --fast5 "${FAST5_DIR}"/fast5 --fastq "${FASTQ}"
done


