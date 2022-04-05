#!/bin/bash

read_type=$1
ext_dir=$2

if [ "${read_type}" = "single" ]
then
  echo 'Checking FASTQs for single-end samples...'
elif [ "${read_type}" = "paired" ]
then
  echo 'Checking FASTQs for paired-end samples...'
else
  false   # Should have been validated earlier in workflow
fi

