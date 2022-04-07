#!/bin/bash

read_type=$1
ext_dir=$2

num_lines=$(( $(wc -l ${ext_dir}/MANIFEST | cut -d " " -f 1) - 1 ))
num_fastq=$(ls ${ext_dir}/*.fastq.gz | wc -l | cut -d " " -f 1)

# Check for no files
if [ ${num_lines} -eq 0 ] || [ ${num_fastq} -eq 0 ]; then
  echo 'There were no FASTQs found! Exiting...'
  exit
fi

# Check for mismatched FASTQ/manifest
if [ "${read_type}" = "single" ]; then
  echo 'Checking FASTQs for single-end samples...'
  if [[ ${num_lines} -ne ${num_fastq} ]]; then
    echo 'The number of FASTQs does not match the manifest! Exiting...'
    exit
  fi

  echo "${num_fastq} single-end FASTQ files were successfully downloaded!"

elif [ "${read_type}" = "paired" ]; then
  echo 'Checking FASTQs for paired-end samples...'
  num_fwd_fq=$(ls ${ext_dir}/*R1*.fastq.gz | wc -l | cut -d " " -f 1)
  num_rev_fq=$(ls ${ext_dir}/*R2*.fastq.gz | wc -l | cut -d " " -f 1)
  num_pairs_man=$(tail -n+2 ${ext_dir}/MANIFEST | cut -d "," -f 1 | sort | uniq | wc -l)

  if [[ ${num_fwd_fq} -ne ${num_rev_fq} ]]; then
    echo 'There are different numbers of forward and reverse FASTQs! Exiting...'
    exit
  elif [[ "$(( num_fwd_fq * 2 ))" -ne ${num_lines} ]]; then
    echo 'The total number of FASTQs does not match the manifest! Exiting...'
    exit
  elif [[ ${num_pairs_man} -ne ${num_fwd_fq} ]]; then
    echo 'The number of FASTQ pairs does not match the manifest! Exiting...'
    exit
  fi

  echo "${num_pairs_man} FASTQ pairs were successfully downloaded!"

else     # Should have been validated earlier in workflow
  false
fi

