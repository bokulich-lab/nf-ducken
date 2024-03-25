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

### 1.3.  Downloads and directory organization

1. Create a dedicated directory

## Frequently Asked Questions

> Why does this pipeline wrap QIIME 2 commands?

TBA

> Why is this called `nf-ducken`? What even is a ducken?

TBA

> Who should we contact if we have suggested features or questions?

For features, please feel free to open a GitHub issue! Otherwise, shoot us an email at lina [dot] kim [at] hest.ethz.ch.

## References