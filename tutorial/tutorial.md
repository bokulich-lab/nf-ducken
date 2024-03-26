# nf-ducken Tutorial

A Nextflow pipeline enabling high-throughput, parallelized meta-analysis of marker gene data.

No more need to manually launch one analysis step after another. With `nf-ducken`, execute a single workflow that will take you through all necessary pre-processing steps:

1. Data import: Import local FASTQ files (`qiime tools import`) or download from the SRA (`q2-fondue`)
2. Optional adapter trimming: `q2-cutadapt`
3. Initial quality control and denoising: `q2-dada2`
4. Optional chimera filtering: `q2-vsearch`
5. Optional closed-reference OTU clustering: `q2-vsearch`
6. Taxonomy classification: `q2-sample-classifier`
7. Collapse to taxon of interest: `q2-taxa`

These are illustrated, with corresponding stepwise commands, [in this large flowchart](https://raw.githubusercontent.com/bokulich-lab/nf-ducken/main/assets/images/workflow_wcode.svg).

This tutorial has two parallel components: The **download** tutorial (Section 2) and the **import** tutorial (Section 3). Feel free to run one or both. If you plan to run `nf-ducken` from FASTQ files you will download from the SRA or ENA, select the **download** tutorial. If you plan to run `nf-ducken` on FASTQ files already on your computer, select the **import** tutorial.

## 1.  Setup

### 1.1.  Package management

:exclamation: Do you already have Conda installed on your machine? If so, skip to "Downloads"... unless you have an Apple device with an M1+ processor. If so, skip to **MacOS**.

<details>
    <summary><b>MacOS/Linux</b></summary>

    :apple: **Do you have a machine with a newer Apple processor (M1/M2/M3)?** Conda environments require emulation using Rosetta, due to the lack of certain packages for the ARM64 architecture otherwise available with Intel processors. Please follow the [installation and setup instructions here](https://support.apple.com/en-us/HT211861) for details.

    1. Download and install [Miniconda3](https://docs.conda.io/projects/miniconda/en/latest/miniconda-install.html).

</details>

<details>
    <summary><b>Windows</b></summary>

    1. You need a shell-based terminal. We recommend the [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/install) or a [virtual machine](https://www.virtualbox.org/wiki/Downloads); please install one of these if you have not already.
    2. Download and install [Miniconda3](https://docs.conda.io/projects/miniconda/en/latest/miniconda-install.html).

</details>

### 1.2.  Environment setup

It is good practice to create a new virtual environment for different uses. We follow this practice here by creating a Conda virtual environment to launch `nf-ducken`.

```shell
conda create -n nextflow bioconda::nextflow
conda activate nextflow
pwd
```

### 1.3.  Select downstream processes

This tutorial has two parallel components: The **download** tutorial (Section 2) and the **import** tutorial (Section 3). Feel free to run one or both. If you plan to run `nf-ducken` from FASTQ files you will download from the SRA or ENA, select the **download** tutorial. If you plan to run `nf-ducken` on FASTQ files already on your computer, select the **import** tutorial.

## 2.  Download tutorial

### 2.1.  Directory organization

1. Create a dedicated directory on your local computer for this tutorial. We suggest `~/Desktop/tutorial/` for simplicity.
2. Download (or copy) the following two files:
  * [`download_tutorial_ids.tsv`](https://github.com/bokulich-lab/nf-ducken/tutorial/download_tutorial/download_tutorial_ids.tsv): A tab-separated file (TSV) of SRA IDs for download. It currently contains three IDs for three pairs of FASTQs.
  * [`download_tutorial_params.config`](https://github.com/bokulich-lab/nf-ducken/tutorial/download_tutorial/download_tutorial_params.config): A configuration file to pass in parameters for your `nf-ducken` run. It has already been filled in with required parameters.
3. Organize your files in your local directory. We suggest a file organization akin to this:
```text
Desktop/
|-- tutorial/    # your current working directory!
    |-- download_tutorial_ids.tsv
    |-- download_tutorial_params.config
```
4. Double-check your current working directory by running `pwd` in the terminal. You should be in `~/Desktop/tutorial/` or similar.

### 2.2.  Modify input ID file

`download_tutorial_ids.tsv` currently contains a list of three SRA IDs to download three pairs of FASTQs. Feel free to modify this list with your own preferred IDs. Input IDs can be NCBI BioProject numbers, NCBI BioSample numbers, SRA Experiment numbers, or SRA Run numbers. [See here for explanations](https://bioinformatics.ccr.cancer.gov/docs/b4b/Module1_Unix_Biowulf/Lesson6/#sra-terms-to-know) of each type of ID number.

Each ID must have its own line. The very first line **must** be `sample-id`; even `sample_id` will throw an error!

## 2.3.  Modify input configuration file

`download_tutorial_params.config` currently contains minimal runtime parameters for your execution. It works now as provided, but follow these instructions if you would like to make changes.

Required parameters:
* `read_type`: Currently set to `"paired"`. Normally this depends on whether your FASTQs are single- or paired-end; in our case, our data are paired-end.
* `pipeline_type`: Currently set to `"download"`. In the **import** tutorial you will set this to `"import"`.
* `outdir`: Currently sThis is the name of the folder where your outputs are saved. Set to a string like `"results"` for clarity.
* `inp_id_file`: Set to the location of your ID file. This is how `nf-ducken` will know how to access the correct file. If it matters to you: Absolute file paths are preferred, but relative file paths work too.
* `email_address`: Set to your email address. This is required for NCBI server downloads.

This input file should be a plain text file i.e. if using MacOS TextEdit, select “Format” → “Make Plain Text”. All variables go inside the curly braces, and nearly all variable assignments (to the right of the `=` sign) should be surrounded by quotation marks. See the [`nf-ducken` README](https://github.com/bokulich-lab/nf-ducken/blob/main/README.md) for more details and other available parameters.

### 2.3.  Execute pipeline



## 3.  Import tutorial

TBA

## Frequently Asked Questions

> Why does this pipeline wrap QIIME 2 commands?

TBA

> Why is this called `nf-ducken`? What even is a ducken?

TBA

> Who should we contact if we have suggested features or questions?

For features, please feel free to open a GitHub issue! Otherwise, shoot us an email at lina [dot] kim [at] hest.ethz.ch.

## References