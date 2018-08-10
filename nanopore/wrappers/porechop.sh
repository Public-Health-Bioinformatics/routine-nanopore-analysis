#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Constants
declare -r PORECHOP_QSUB_SCRIPT="/home/dfornika/code/qsub-scripts/nanopore/porechop.qsub" # replace when we decide on a system-wide install location
declare -r QSUB_ERROR_LOG_DIR="/data/minion/basecalls/qsub_logs/$( date --iso-8601 )/porechop"
declare -r QSUB_OUTPUT_LOG_DIR="/data/minion/basecalls/qsub_logs/$( date --iso-8601 )/porechop"

USAGE="$( basename $BASH_SOURCE ) [-h] -i|--input <inputdir>"

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
    # Base directory for run (must contain fastq.gz files)
    INPUT="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1")
    shift # past argument
    ;;
  esac
done

# Prepare log dirs
mkdir -p "${QSUB_ERROR_LOG_DIR}"
mkdir -p "${QSUB_OUTPUT_LOG_DIR}"

# Print some info to stderr for debugging & provenance
(>&2 echo INPUT               = "${INPUT}" )
(>&2 echo QSUB_ERROR_LOG_DIR  = "${QSUB_ERROR_LOG_DIR}" )
(>&2 echo QSUB_OUTPUT_LOG_DIR = "${QSUB_OUTPUT_LOG_DIR}" )

# Submit qsub job
for FASTQ in "${INPUT}"/*.fastq.gz; do
    FASTQ_BASENAME=$( basename "${FASTQ}" )
    qsub -o "${QSUB_OUTPUT_LOG_DIR}" -e "${QSUB_ERROR_LOG_DIR}" "${PORECHOP_QSUB_SCRIPT}" -i "${FASTQ}" -o "${INPUT}"/"${FASTQ_BASENAME%.fastq.gz}".porechop.fastq.gz
done

