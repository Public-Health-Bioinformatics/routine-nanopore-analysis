#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir="$( dirname "$0" )"
source "${script_dir}"/../config.conf

# Constants
declare -r NANOPOLISH_INDEX_QSUB_SCRIPT="${routine_nanopore_processing_repo_root_dir}"/qsub_scripts/nanopolish_index.qsub
declare -r QSUB_ERROR_LOG_DIR="/data/minion/basecalls/qsub_logs/$( date --iso-8601 )/nanopolish_index"
declare -r QSUB_OUTPUT_LOG_DIR="/data/minion/basecalls/qsub_logs/$( date --iso-8601 )/nanopolish_index"

USAGE=$'$(basename "$0") [-h] -5|--fast5 FAST5_DIR -q|--fastq MERGED_FASTQ_DIR -s|--sequencing_summary SEQUENCING_SUMMARY'

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
    -s|--sequencing_summary)
    # The merged sequencing_summary.txt file
    sequencing_summary="$2"
    shift # past argument
    shift # past value
    ;;
  esac
done

(>&2 echo sequencing_summary  = "${sequencing_summary}" )
(>&2 echo FAST5_DIR  = "${FAST5_DIR}" )
(>&2 echo FASTQ_DIR  = "${FASTQ_DIR}" )
(>&2 echo QSUB_ERROR_LOG_DIR  = "${QSUB_ERROR_LOG_DIR}" )
(>&2 echo QSUB_OUTPUT_LOG_DIR = "${QSUB_OUTPUT_LOG_DIR}" )

# Prepare log dirs
mkdir -p "${QSUB_ERROR_LOG_DIR}"
mkdir -p "${QSUB_OUTPUT_LOG_DIR}"


# Submit qsub jobs
for FASTQ in $( find "${FASTQ_DIR}" -name '*.fastq.gz'); do
    qsub -o "${QSUB_OUTPUT_LOG_DIR}" -e "${QSUB_ERROR_LOG_DIR}" \
	 "${NANOPOLISH_INDEX_QSUB_SCRIPT}" \
	 --fast5 "${FAST5_DIR}" \
	 -s "${sequencing_summary}" \
	 --fastq "${FASTQ}"
done


