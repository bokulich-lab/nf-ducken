#!/bin/bash

inp_file=$1
suffix=${2:-_split.txt}

header=$(head -1 "${inp_file}")
tail -n+2 "${inp_file}" | while read line; do
  sample=( "${line}" )
  echo "${header}" >> "${sample}${suffix}"
  echo "${line}" >> "${sample}${suffix}"
done
