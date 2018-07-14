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

# Defaults
CONFIG="r94_450bps_linear.cfg"
BARCODING=false
LOWER_FAST5_DIR_NUM=0
UPPER_FAST5_DIR_NUM=-1

USAGE=$'$(basename "$0") [-h] [-c config] [-b|--barcoding] -i|--input <inputdir>\nNOTE: Default config is: r94_450bps_linear.cfg'

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

# Print some info to stderr for debugging & provenance
(>&2 echo NUM_FAST5_SUBDIRS   = "${NUM_FAST5_SUBDIRS}" )
(>&2 echo LOWER_FAST5_DIR_NUM = "${LOWER_FAST5_DIR_NUM}" )
(>&2 echo UPPER_FAST5_DIR_NUM = "${UPPER_FAST5_DIR_NUM}" )
(>&2 echo CONFIG              = "${CONFIG}" )
(>&2 echo BARCODING           = "${BARCODING}" )
(>&2 echo ALBACORE_VERSION    = "${ALBACORE_VERSION}" )

# Submit qsub job
qsub -t $(( $LOWER_FAST5_DIR_NUM + 1 )):$( if [[ "${UPPER_FAST5_DIR_NUM}" = -1 ]]; then echo $NUM_FAST5_SUBDIRS; else echo $(( $UPPER_FAST5_DIR_NUM + 1 )); fi ) "${ALBACORE_QSUB_SCRIPT}" -c "${CONFIG}" -i "${INPUT}" -o "${OUTPUT_BASE_DIR}"/$( basename "$INPUT" )/albacore-"${ALBACORE_VERSION}"_$( cut -d '.' -f1 <<< "${CONFIG}" ) $( if [[ "${BARCODING}" = true ]]; then echo "--barcoding"; fi )

