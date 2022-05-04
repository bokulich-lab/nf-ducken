#!/bin/bash

fq_dir=$(realpath $1)
out_fname=$2
read_type=${3:-paired}         # single or paired
suffix=${4:-_R[1-2].fastq.gz}  # default suffix, paired

# Set up header
T=$(printf '\t')

if [ ${read_type} = "single" ]; then
  header="sample-id${T}absolute-filepath"
elif [ ${read_type} = "paired" ]; then
  header="sample-id${T}forward-absolute-filepath${T}reverse-absolute-filepath"
fi

# Generate array of sample IDs
declare -a arr=()

for fname in ${fq_dir}/*${suffix}; do
  fbase=$(basename ${fname})
  id=${fbase%${suffix}}
  arr+=( ${id} )
done

id_arr=($(echo ${arr[@]} | tr [:space:] '\n' | awk '!a[$1]++'))

# Populate manifest
echo ${header} > ${out_fname}

if [ ${read_type} = "single" ]; then
  for id in ${id_arr[@]}; do
    fpath=$(ls ${fq_dir}/${id}${suffix})
    echo "${id}${T}${fpath}" >> ${out_fname}
  done
elif [ ${read_type} = "paired" ]; then
  for id in ${id_arr[@]}; do
    if ls ${fq_dir}/${id}*R1*fastq* 1> /dev/null 2>&1 && ls ${fq_dir}/${id}*R2*fastq* 1> /dev/null 2>&1; then
      r1=$(ls ${fq_dir}/${id}*R1*fastq*)
      r2=$(ls ${fq_dir}/${id}*R2*fastq*)
      echo "${id}${T}${r1}${T}${r2}" >> ${out_fname}
    else
      continue
    fi
  done
fi
