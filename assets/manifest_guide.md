# Guide: Manifest Generation

Easily generate a QIIME 2-friendly FASTQ manifest file (also known as a mapping file) using the module `make_manifest.py`, found in `nf-ducken/bin/`. This accommodates both single- and paired-end FASTQ inputs.

Assumptions:

* FASTQ files are already demultiplexed i.e. samples run in the same lane have been separated into individual FASTQs by index
* All relevant FASTQ files are in the same directory
* FASTQ file names start with alphanumeric characters, with no leading special characters

## Setup

The program `make_manifest.py` is run from the command line. Your terminal environment requires the following software:

* Python 3
* `numpy`
* `pandas`

Instructions for downloading Python 3 [can be found here](https://www.python.org/downloads/). `numpy` and `pandas` are Python packages that can be installed by running `pip install numpy pandas` or `conda install numpy pandas` on the terminal.

## Directory structure

We recommend running `make_manifest.py` based on the following directory structure:

```
|-- fastq_processing/
    |-- nf-ducken/    # may also be known as turducken_code/
        |-- assets/
        |-- bin/
        ...
    |-- data/
        |-- 1000A_R1.fastq.gz
        |-- 1000A_R2.fastq.gz
        |-- 1000B_R1.fastq.gz
        |-- 1000B_R2.fastq.gz
        |-- 1000C_R1.fastq.gz
        |-- 1000C_R2.fastq.gz
        ...
```

Your location in the terminal (your working directory) should be `fastq_processing/` or similar.

## Execution

###1. Confirm you have the necessary packages downloaded.

Run:

```commandline
$ python nf-ducken/bin/make_manifest.py --help
```

If you get the message `ModuleNotFoundError: No module named 'numpy'` or similar: Please go back to the "Setup" section above and install the necessary packages.

If you get the message `python: can't open file 'nf-ducken/bin/make_manifest.py': [Errno 2] No such file or directory`: Change your working directory so you are in `fastq_processing/` or similar. You should NOT be in `fastq_processing/nf-ducken/` or `fastq_processing/data/`.

You can double-check your location in the terminal with the command:

```commandline
$ pwd
```

###2. Double-check your data are found in `fastq_processing/data/`.

Run:

```commandline
$ ls data/
```

The output should list all the FASTQ files you want a manifest for. If you get an error or nothing shows up, please double-check your location on the terminal with `pwd` or double-check the location of your FASTQ files.

###3. (Optional) Select an appropriate suffix.

Each sample name will be decided based on the FASTQ filename suffix. For example:

* For the single-end FASTQ file `ABCDE_R1.fastq.gz`, the FASTQ suffix is `_R1.fastq.gz`.
* For the single-end FASTQ file `ABCDE_00_L001_R1_001.fastq.gz`, the FASTQ suffix is `_00_L001_R1_001.fastq.gz`.

In the above cases, you would have the flag `--suffix` in your command, followed by the suffix.

* For the FASTQ pairs `1000A_R1.fastq.gz` and `1000A_R2.fastq.gz`, the FASTQ suffixes are `_R1.fastq.gz` and `_R2.fastq.gz`.
* For the FASTQ pairs `ABCDE_00_L001_R1_001.fastq.gz` and `ABCDE_00_L001_R2_001.fastq.gz`, the FASTQ suffixes are `_00_L001_R1_001.fastq.gz` and `_00_L001_R2_001.fastq.gz`.

In the above cases, you would have the flags `--r1_suffix` and `--r2_suffix` in your command, followed by the suffixes.

###4. Run the manifest generator.

Run for a single-end run:

```commandline
python nf-ducken/bin/make_manifest.py  \
    --input_dir data/  \
    --read_type ${read_type}  \
    --output_fname ${output_fname}  \
    --suffix ${suffix}
```

or for a paired-end run:

```commandline
python nf-ducken/bin/make_manifest.py  \
    --input_dir data/  \
    --read_type ${read_type}  \
    --output_fname ${output_fname}  \
    --r1_suffix ${r1_suffix}  \
    --r2_suffix ${r2_suffix}
```

Replace `${read_type}` with either `single` or `paired`. Replace `${output_fname}` with the desired name of your manifest file, such as `manifest.tsv`. For QIIME 2 purposes, your manifest file should end with the extension `.tsv`!

If you have a single-end run, replace `${suffix}` with the FASTQ suffix you determined in step 3. If you have a paired-end run, replace `${r1_suffix}` and `${r2_suffix}` with the two FASTQ suffixes you determined in step 3.

As an example, for a single-end run:

```commandline
python nf-ducken/bin/make_manifest.py  \
    --input_dir data/  \
    --read_type single  \
    --output_fname manifest.tsv  \
    --suffix _00_L001_R1_001.fastq.gz
```

or for a paired-end run:

```commandline
python nf-ducken/bin/make_manifest.py  \
    --input_dir data/  \
    --read_type paired  \
    --output_fname manifest.tsv  \
    --r1_suffix _00_L001_R1_001.fastq.gz  \
    --r2_suffix _00_L001_R2_001.fastq.gz
```

## Output

Your output manifest file can be found in `fastq_processing/` with the name you gave it under `--output_fname`. It will look something like this for a single-end run:

```
sample-id       absolute-filepath
sample1   /Users/uname/Documents/fastq_processing/data/sample1_00_L001_R1_001.fastq.gz
sample2   /Users/uname/Documents/fastq_processing/data/sample2_00_L001_R1_001.fastq.gz
sample3   /Users/uname/Documents/fastq_processing/data/sample3_00_L001_R1_001.fastq.gz
```

For a paired-end run:

```
sample-id       forward-absolute-filepath       reverse-absolute-filepath
sample1   /Users/uname/Documents/fastq_processing/data/sample1_00_L001_R1_001.fastq.gz   /Users/uname/Documents/fastq_processing/data/sample1_00_L001_R2_001.fastq.gz
sample2   /Users/uname/Documents/fastq_processing/data/sample2_00_L001_R1_001.fastq.gz   /Users/uname/Documents/fastq_processing/data/sample2_00_L001_R2_001.fastq.gz
sample3   /Users/uname/Documents/fastq_processing/data/sample3_00_L001_R1_001.fastq.gz   /Users/uname/Documents/fastq_processing/data/sample3_00_L001_R2_001.fastq.gz
```

For more details, see the [QIIME 2 Documentation](https://docs.qiime2.org/2024.2/tutorials/importing/#id18) for the standards guiding the QIIME 2 manifest format.

## Help

Evoke the help message for the module (on the command line) as follows:

```commandline
python nf-ducken/bin/make_manifest.py --help

usage: make_manifest.py [-h] -i INPUT_DIR --read_type {paired,single} [-o OUTPUT_FNAME] [--suffix SUFFIX] [--r1_suffix R1_SUFFIX]
                        [--r2_suffix R2_SUFFIX]

options:
  -h, --help            show this help message and exit
  -i INPUT_DIR, --input_dir INPUT_DIR
                        Path to directory containing FASTQ files.
  --read_type {paired,single}
                        Read type of FASTQ files, 'single' or 'paired'.
  -o OUTPUT_FNAME, --output_fname OUTPUT_FNAME
                        File name of output manifest.
  --suffix SUFFIX       Suffix for FASTQ files.
  --r1_suffix R1_SUFFIX
                        For paired-end samples, suffix for forward reads.
  --r2_suffix R2_SUFFIX
                        For paired-end samples, suffix for reverse reads.
```