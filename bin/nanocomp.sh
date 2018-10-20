#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir="$( dirname "$0" )"
source "${script_dir}"/../config.conf

# Constants
declare -r nanocomp_qsub_script="${routine_nanopore_processing_repo_root_dir}"/qsub_scripts/nanocomp.qsub
declare -r OUTPUT_BASE_DIR="${minion_data_base_dir}"/quality_control
declare -r QSUB_ERROR_LOG_DIR="/data/minion/quality_control/qsub_logs/$( date --iso-8601 )/nanocomp"
declare -r QSUB_OUTPUT_LOG_DIR="/data/minion/quality_control/qsub_logs/$( date --iso-8601 )/nanocomp"

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
    # Base directory for run
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


# Parse timestamp from directory and prepare parent directory with no timestamp (date only)
# Multiple run re-starts will be collected inside the same parent dir
# YYYYMMDD_sample_libraryprep/YYYYMMDD_TIME_sample_libraryprep
INPUT_BASENAME=$( basename "${INPUT}" )
INPUT_DIRNAME=$( dirname "${INPUT}" )
OUTPUT_PATH=$( echo "${INPUT_DIRNAME}" | cut -d'/' -f5-)/"${INPUT_BASENAME}"
INPUT_PARENT_BASENAME=$( basename $( dirname "${INPUT}" ) )

# mkdir -p "${OUTPUT_BASE_DIR}"/"${INPUT_PARENT_BASENAME}"

# Prepare log dirs
mkdir -p "${QSUB_ERROR_LOG_DIR}"
mkdir -p "${QSUB_OUTPUT_LOG_DIR}"

# Print some info to stderr for debugging & provenance
(>&2 echo INPUT               = "${INPUT}" )
(>&2 echo INPUT_BASENAME      = "${INPUT_BASENAME}" )
(>&2 echo INPUT_DIRNAME       = "${INPUT_DIRNAME}" )
(>&2 echo OUTPUT_BASE_DIR     = "${OUTPUT_BASE_DIR}" )
(>&2 echo OUTPUT_PATH         = "${OUTPUT_PATH}" )
(>&2 echo QSUB_ERROR_LOG_DIR  = "${QSUB_ERROR_LOG_DIR}" )
(>&2 echo QSUB_OUTPUT_LOG_DIR = "${QSUB_OUTPUT_LOG_DIR}" )

# Submit qsub job
qsub -o "${QSUB_OUTPUT_LOG_DIR}" -e "${QSUB_ERROR_LOG_DIR}" \
     "${nanocomp_qsub_script}" \
     -o "${OUTPUT_BASE_DIR}"/"${OUTPUT_PATH}" \
     --fastq "${INPUT}"/*.fastq.gz


