#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

declare -i NUM_FAST5_DIRS
declare -i LOWER_FAST5_DIR_NUM
declare -i UPPER_FAST5_DIR_NUM

# Constants
declare -r ALBACORE_QSUB_SCRIPT="/home/dfornika/code/qsub-scripts/nanopore/albacore.qsub" # replace when we decide on a system-wid install location
declare -r OUTPUT_BASE_DIR="/data/minion/basecalls"
declare -r ALBACORE_SCRIPT="/opt/miniconda2/envs/nanopore/bin/read_fast5_basecaller.py"
ALBACORE_VERSION=$( "${ALBACORE_SCRIPT}" --version | cut -d "(" -f2 | cut -d ")" -f1 | cut -d' ' -f2)
declare -r QSUB_ERROR_LOG_DIR="/data/minion/basecalls/qsub_logs/$( date --iso-8601 )/albacore"
declare -r QSUB_OUTPUT_LOG_DIR="/data/minion/basecalls/qsub_logs/$( date --iso-8601 )/albacore"

# Defaults
CONFIG="r94_450bps_linear.cfg"
BARCODING=false
LOWER_FAST5_DIR_NUM=0
UPPER_FAST5_DIR_NUM=-1

USAGE="$( basename $BASH_SOURCE ) [-h] [-c config] [-b|--barcoding] [-l|--lower_fast5_dir_num] [-u|--upper_fast5_dir_num] -i|--input <inputdir>"

if [[ $# -eq 0 || $1 == "--help" ||  $1 == "-h" ]] 
then 
    echo "Usage: ${USAGE}"
    echo "NOTE: Default config is: ${CONFIG}"
    exit 0
fi



while [[ $# -gt 0 ]]
do
  key="$1"
  
  case $key in
    -i|--input)
    # Base directory for run (must contain a 'fast5' subdir)
    INPUT="$2"
    shift # past argument
    shift # past value
    ;;
    -c|--config)
    CONFIG="$2"
    shift # past argument
    shift # past value
    ;;
    -b|--barcoding)
    # No value, just the argument
    BARCODING=true
    shift # past argument
    ;;
    -l|--lower_fast5_dir_num)
    LOWER_FAST5_DIR_NUM="$2"
    shift # past argument
    shift # past value
    ;;
    -u|--upper_fast5_dir_num)
    UPPER_FAST5_DIR_NUM="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1")
    shift # past argument
    ;;
  esac
done

NUM_FAST5_SUBDIRS=$( ls -1 "$INPUT"/fast5 | wc -l )

if [[ "${UPPER_FAST5_DIR_NUM:-}" > -1 && "${LOWER_FAST5_DIR_NUM}" > "${UPPER_FAST5_DIR_NUM}" ]];
then
    echo "ERROR: Upper fast5 dir must be greater than or equal to Lower fast5 dir."
    exit 1
fi

# Prepare parent directory with no timestamp (date only)
# Multiple run re-starts will be collected inside the same parent dir
# YYYYMMDD_sample_libraryprep/YYYYMMDD_TIME_sample_libraryprep
INPUT_BASENAME=$( basename "${INPUT}" )
INPUT_PARENT_BASENAME=$( basename $( dirname "${INPUT}" ) )

mkdir -p "${OUTPUT_BASE_DIR}"/"${INPUT_PARENT_BASENAME}"

# Prepare log dirs
mkdir -p "${QSUB_ERROR_LOG_DIR}"
mkdir -p "${QSUB_OUTPUT_LOG_DIR}"

# Print some info to stderr for debugging & provenance
(>&2 echo INPUT               = "${INPUT}" )
(>&2 echo INPUT_BASENAME      = "${INPUT_BASENAME}" )
(>&2 echo INPUT_PARENT_BASENAME = "${INPUT_PARENT_BASENAME}" )
(>&2 echo NUM_FAST5_SUBDIRS   = "${NUM_FAST5_SUBDIRS}" )
(>&2 echo LOWER_FAST5_DIR_NUM = "${LOWER_FAST5_DIR_NUM}" "(Default is 0 if unspecified)")
(>&2 echo UPPER_FAST5_DIR_NUM = "${UPPER_FAST5_DIR_NUM}" "(Default is -1 if unspecified and upper limit will be auto-detected)")
(>&2 echo CONFIG              = "${CONFIG}" )
(>&2 echo BARCODING           = "${BARCODING}" )
(>&2 echo ALBACORE_VERSION    = "${ALBACORE_VERSION}" )
(>&2 echo QSUB_ERROR_LOG_DIR  = "${QSUB_ERROR_LOG_DIR}" )
(>&2 echo QSUB_OUTPUT_LOG_DIR = "${QSUB_OUTPUT_LOG_DIR}" )

# Submit qsub job
qsub -o "${QSUB_OUTPUT_LOG_DIR}" -e "${QSUB_ERROR_LOG_DIR}" -t $(( $LOWER_FAST5_DIR_NUM + 1 )):$( if [[ "${UPPER_FAST5_DIR_NUM}" = -1 ]]; then echo $NUM_FAST5_SUBDIRS; else echo $(( $UPPER_FAST5_DIR_NUM + 1 )); fi ) "${ALBACORE_QSUB_SCRIPT}" -c "${CONFIG}" -i "${INPUT}" -o "${OUTPUT_BASE_DIR}"/"${INPUT_PARENT_BASENAME}"/"${INPUT_BASENAME}"/albacore-"${ALBACORE_VERSION}"_$( cut -d '.' -f1 <<< "${CONFIG}" ) $( if [ "$BARCODING" = true ]; then echo "--barcoding"; fi )

