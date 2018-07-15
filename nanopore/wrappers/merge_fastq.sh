#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Constants
declare -r MERGE_FASTQ_QSUB_SCRIPT="/home/dfornika/code/qsub-scripts/nanopore/merge_fastq.qsub" # replace when we decide on a system-wide install location

# Defaults
BARCODING=false

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
    # Base directory for run (must contain a 'fast5' subdir)
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

if [[ $BARCODING == false ]]; then
  qsub MERGE_FASTQ_QSUB_SCRIPT --pass
  qsub MERGE_FASTQ_QSUB_SCRIPT --fail
else
  for $BARCODE_ID in $( ls -1 "${INPUT}"/0/workspace/pass ); do
    qsub MERGE_FASTQ_QSUB_SCRIPT --pass
  done
  for $BARCODE_ID in $( ls -1 "${INPUT}"/0/workspace/fail ); do
    qsub MERGE_FASTQ_QSUB_SCRIPT --fail
  done
fi

