#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir="$( dirname "$0" )"
source "${script_dir}"/../config.conf

albacore_version="2.3.1"

declare -i num_fast5_dirs
declare -i lower_fast5_dir_num
declare -i upper_fast5_dir_num

# Constants
declare -r albacore_qsub_script="${routine_nanopore_processing_repo_root_dir}"/qsub_scripts/albacore.qsub
declare -r output_base_dir="${minion_data_base_dir}"/basecalls
declare -r albacore_script="${conda_envs_dir}"/albacore-"${albacore_version}"/bin/read_fast5_basecaller.py
reported_albacore_version=$( "${albacore_script}" --version | cut -d "(" -f2 | cut -d ")" -f1 | cut -d' ' -f2)
declare -r qsub_error_log_dir="${minion_data_base_dir}/basecalls/qsub_logs/$( date --iso-8601 )/albacore"
declare -r qsub_output_log_dir="${minion_data_base_dir}/data/minion/basecalls/qsub_logs/$( date --iso-8601 )/albacore"

# Defaults
albacore_config="r94_450bps_linear.cfg"
barcoding=false
lower_fast5_dir_num=0
upper_fast5_dir_num=-1

usage="$( basename $BASH_SOURCE ) [-h] [-c config] [-b|--barcoding] [-l|--lower_fast5_dir_num] [-u|--upper_fast5_dir_num] -i|--input <inputdir>"

if [[ $# -eq 0 || $1 == "--help" ||  $1 == "-h" ]] 
then 
    echo "Usage: ${usage}"
    echo "NOTE: Default config is: ${albacore_config}"
    exit 0
fi



while [[ $# -gt 0 ]]
do
  key="$1"
  
  case $key in
    -i|--input)
    # Base directory for run (must contain a 'fast5' subdir)
    input_dir="$2"
    shift # past argument
    shift # past value
    ;;
    -c|--config)
    albacore_config="$2"
    shift # past argument
    shift # past value
    ;;
    -b|--barcoding)
    # No value, just the argument
    barcoding=true
    shift # past argument
    ;;
    -l|--lower_fast5_dir_num)
    lower_fast5_dir_num="$2"
    shift # past argument
    shift # past value
    ;;
    -u|--upper_fast5_dir_num)
    upper_fast5_dir_num="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1")
    shift # past argument
    ;;
  esac
done

num_fast5_subdirs=$( ls -1 "$input_dir"/fast5 | wc -l )

if [[ "${lower_fast5_dir_num:-}" > -1 && "${lower_fast5_dir_num}" > "${upper_fast5_dir_num}" ]];
then
    echo "ERROR: Upper fast5 dir must be greater than or equal to Lower fast5 dir."
    exit 1
fi

# Prepare parent directory with no timestamp (date only)
# Multiple run re-starts will be collected inside the same parent dir
# YYYYMMDD_sample_libraryprep/YYYYMMDD_TIME_sample_libraryprep
input_dir_basename=$( basename "${input_dir}" )
input_dir_parent_basename=$( basename $( dirname "${input_dir}" ) )

mkdir -p "${output_base_dir}"/"${input_dir_parent_basename}"

# Prepare log dirs
mkdir -p "${qsub_error_log_dir}"
mkdir -p "${qsub_output_log_dir}"

# Print some info to stderr for debugging & provenance
(>&2 echo "Input directory:" "${input_dir}" )
(>&2 echo "Basename of input directory:" "${input_dir_basename}" )
(>&2 echo "Basename of input directory parent directory:" "${input_dir_parent_basename}" )
(>&2 echo "Number of fast5 sub-directories to basecall:" "${num_fast5_subdirs}" )
(>&2 echo "Lower-bound fast5 directory number:" "${lower_fast5_dir_num}" "(Default is 0 if unspecified)")
(>&2 echo "Upper-bound fast5 directory number:" "${upper_fast5_dir_num}" "(Default is -1 if unspecified and upper limit will be auto-detected)")
(>&2 echo "Albacore config:" "${albacore_config}" )
(>&2 echo "Demultiplex barcodes:" "${barcoding}" )
(>&2 echo "Albacore version:"    = "${reported_albacore_version}" )
(>&2 echo "qsub Error Log directory:" "${qsub_error_log_dir}" )
(>&2 echo "qsub Standard Output Log directory:" "${qsub_output_log_dir}" )

# Submit qsub job
qsub -o "${qsub_output_log_dir}" -e "${qsub_error_log_dir}" \
     -t $(( $lower_fast5_dir_num + 1 )):$( if [[ "${upper_fast5_dir_num}" = -1 ]]; then echo $num_fast5_subdirs; else echo $(( $upper_fast5_dir_num + 1 )); fi ) \
     "${albacore_qsub_script}" \
     -c "${albacore_config}" \
     -i "${input_dir}" \
     -o "${output_base_dir}"/"${input_dir_parent_basename}"/"${input_dir_basename}"/albacore-"${albacore_version}"_$( cut -d '.' -f1 <<< "${albacore_config}" ) \
     $( if [ "$barcoding" = true ]; then echo "--barcoding"; fi )

