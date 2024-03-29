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

**NOTE:** This tutorial requires an active Internet connection!

## 1.  Setup

### 1.1.  Package management

:exclamation: Do you already have Conda installed on your machine? If so, skip to "Downloads"... unless you have an Apple device with an M1+ processor. If so, skip to **MacOS**.

<details>
    <summary><b>MacOS/Linux</b></summary>
    <br>
    <b>Do you have a machine with a newer Apple processor (M1/M2/M3)?</b> Conda environments require emulation using Rosetta, due to the lack of certain packages for the ARM64 architecture otherwise available with Intel processors. Please follow the <a href="https://support.apple.com/en-us/HT211861">installation and setup instructions here</a> for details.
    <br><br>
    <ol type="1">
        <li>Download and install <a href="https://docs.conda.io/projects/miniconda/en/latest/miniconda-install.html">Miniconda3</a>.</li>
    </ol>
</details>

<details>
    <summary><b>Windows</b></summary>
    <br>
    <ol type="1">
        <li>You need a shell-based terminal. We recommend the <a href="https://learn.microsoft.com/en-us/windows/wsl/install">Windows Subsystem for Linux</a> or a <a href="https://www.virtualbox.org/wiki/Downloads">virtual machine</a>; please install one of these if you have not already.</li>
        <li>Download and install <a href="https://docs.conda.io/projects/miniconda/en/latest/miniconda-install.html">Miniconda3</a>.</li>
    </ol>
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

## 2.  Download Tutorial

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
* `outdir`: Currently sThis is the name of the folder where your outputs are saved. Set to a string like `"download_tutorial_results"` for clarity.
* `inp_id_file`: Set to the location of your ID file. This is how `nf-ducken` will know how to access the correct file. If it matters to you: Absolute file paths are preferred, but relative file paths work too.
* `email_address`: Set to your email address. This is required for NCBI server downloads.

This input file should be a plain text file i.e. if using MacOS TextEdit, select “Format” → “Make Plain Text”. All variables go inside the curly braces, and nearly all variable assignments (to the right of the `=` sign) should be surrounded by quotation marks. See the [`nf-ducken` README](https://github.com/bokulich-lab/nf-ducken/blob/main/README.md) for more details and other available parameters.

### 2.4.  Execute pipeline

We previously suggested a file structure akin to this:

```text
Desktop/
|-- tutorial/    # your current working directory!
    |-- download_tutorial_ids.tsv
    |-- download_tutorial_params.config
```

Please ensure your working directory is `~/Desktop/tutorial/` with the terminal command `pwd`. Please also ensure your Conda environment `nextflow` is active with the terminal command `conda info`.

Execute your workflow with the following command:

```shell
nextflow run bokulich-lab/nf-ducken -c download_tutorial_params.config -profile conda
```

You're all set! Come back in a few minutes to an hour (depending on your processing power) to your completed workflow.

Your outputs will consist of:

* A feature table collapsed to a specific taxon (default species): This will contain feature counts for every species per sample.
* Workflow statistics, including
  * Clustered feature table, not collapsed to taxon
  * Denoising statistics from DADA2
  * Chimera filtering statistics from VSEARCH
  * MultiQC report containing FASTQ quality and (if conducted) adapter/primer trimming statistics

## 3.  Import Tutorial

### 3.1.  Directory organization

1. Create a dedicated directory on your local computer for this tutorial. We suggest `~/Desktop/tutorial/` for simplicity.
2. Download the following two files:
  * [`import_tutorial_data.zip`](https://polybox.ethz.ch/index.php/s/uDNL1MdZ9d7lS8F/download): A zipped file containing three pairs of FASTQ files.
  * [`import_tutorial_params.config`](https://github.com/bokulich-lab/nf-ducken/tutorial/download_tutorial/download_tutorial_params.config): A configuration file to pass in parameters for your `nf-ducken` run. It has already been filled in with required parameters.
3. Unzip the `import_tutorial_data.zip` file.
4. Organize your files in your local directory. We suggest a file organization akin to this:

```text
Desktop/
|-- tutorial/    # your current working directory!
    |-- import_tutorial_data/
        |-- SRR10138346_00_L001_R1_001.fastq.gz
        |-- SRR10138346_00_L001_R2_001.fastq.gz	
        |-- SRR10948299_00_L001_R1_001.fastq.gz	
        |-- SRR10948299_00_L001_R2_001.fastq.gz
        |-- SRR11115880_00_L001_R1_001.fastq.gz
        |-- SRR11115880_00_L001_R2_001.fastq.gz
        |-- manifest.tsv
    |-- import_tutorial_params.config
```

5. Double-check your current working directory by running `pwd` in the terminal. You should be in `~/Desktop/tutorial/` or similar.

### 3.2.  Modify input manifest file

`manifest.tsv` currently contains a list of three samples to download three pairs of FASTQs. Feel free to modify this list for your own samples. Note that this manifest file must follow [the format described here](https://docs.qiime2.org/2024.2/tutorials/importing/#id18), namely as a tab-separated text file with one sample per line.

This must be a text file with the file extension `.tsv`. If you are saving from Excel, go to “Save As” → “File Format: Tab-delimited Text (.txt)” and save your file as `manifest.txt`. Rename this to `manifest.tsv` later.

## 3.3.  Modify input configuration file

`import_tutorial_params.config` currently contains minimal runtime parameters for your execution. It works now as provided, but follow these instructions if you would like to make changes.

Required parameters:
* `read_type`: Currently set to `"paired"`. Normally this depends on whether your FASTQs are single- or paired-end; in our case, our data are paired-end.
* `pipeline_type`: Currently set to `"import"`. In the **download** tutorial you will set this to `"download"`.
* `outdir`: Currently sThis is the name of the folder where your outputs are saved. Set to a string like `"import_tutorial_results"` for clarity.
* `fastq_manifest`: Set to the location of your manifest file. This is how `nf-ducken` will know how to access the correct FASTQs on your local machine. If it matters to you: Absolute file paths are preferred, but relative file paths work too.

This input file should be a plain text file i.e. if using MacOS TextEdit, select “Format” → “Make Plain Text”. All variables go inside the curly braces, and nearly all variable assignments (to the right of the `=` sign) should be surrounded by quotation marks. See the [`nf-ducken` README](https://github.com/bokulich-lab/nf-ducken/blob/main/README.md) for more details and other available parameters.

### 3.4.  Execute pipeline

We previously suggested a file structure akin to this:

```text
Desktop/
|-- tutorial/    # your current working directory!
    |-- import_tutorial_data/
        |-- SRR10138346_00_L001_R1_001.fastq.gz
        |-- SRR10138346_00_L001_R2_001.fastq.gz	
        |-- SRR10948299_00_L001_R1_001.fastq.gz	
        |-- SRR10948299_00_L001_R2_001.fastq.gz
        |-- SRR11115880_00_L001_R1_001.fastq.gz
        |-- SRR11115880_00_L001_R2_001.fastq.gz
        |-- manifest.tsv
    |-- import_tutorial_params.config
```

Please ensure your working directory is `~/Desktop/tutorial/` with the terminal command `pwd`. Please also ensure your Conda environment `nextflow` is active with the terminal command `conda info`.

Execute your workflow with the following command:

```shell
nextflow run bokulich-lab/nf-ducken -c import_tutorial_params.config -profile conda
```

You're all set! Come back in a few minutes to an hour (depending on your processing power) to your completed workflow.

Your outputs will consist of:

* A feature table collapsed to a specific taxon (default species): This will contain feature counts for every species per sample.
* Workflow statistics, including
  * Clustered feature table, not collapsed to taxon
  * Denoising statistics from DADA2
  * Chimera filtering statistics from VSEARCH
  * MultiQC report containing FASTQ quality and (if conducted) adapter/primer trimming statistics

## Frequently Asked Questions

> Where are the sample data from? 

The sample data are from published human microbiome papers; their authors have done their duty to the scientific community by making their sequence data publicly accessible on the SRA. Three cheers to them!

SRR10138346 [1], SRR10948299 [2], and SRR11115880 [3] are from three separate studies. This is intentional, to highlight the use of `nf-ducken` as a meta-analysis tool across various cohorts and papers.

> Why does this pipeline wrap QIIME 2 commands in Nextflow?

We wanted to establish a computational pipeline to both perform necessary analysis and adhere to good data engineering practices by being:

* scalable, to many hundreds to thousands of samples
* reproducible, keeping record of software versions and environments
* automated, to minimize manual interaction and human error
* standardized, in order that multiple datasets may be analyzed through a uniform workflow

`nf-ducken` wraps QIIME 2 [4], Nextflow [5], and commonly used microbiome analysis tools to promote the aforementioned aims. QIIME 2 lends itself to reproducibility with its integrated provenance tracking and community of developers, while the pipeline manager Nextflow grants features such as intermediate pipeline retries, containerization, and cloud/cluster support.

> Why is this called `nf-ducken`? What even is a ducken?

A [turducken](https://en.wikipedia.org/wiki/Turducken) is an unholy amalgamation of a dish comprising a chicken inside a duck inside a turkey. The name is thus a combination of the words *turkey*, *duck*, and *chicken*.

Our sister project [`q2-turducken`](https://github.com/bokulich-lab/q2-turducken) is a QIIME 2 plugin wrapping a Nextflow pipeline made up of QIIME 2 commands. `nf-ducken` is the above pipeline, the inner meat of Nextflow wrapping QIIME 2. As this pipeline is two-layered instead of three, we fondly dub it a **ducken**.

> Who should we contact if we have suggested features or questions?

For features, please feel free to open a GitHub issue! Otherwise, shoot us an email at lina [dot] kim [at] hest.ethz.ch.

## References

1. [Golob et al. (2019)](https://doi.org/10.1182/bloodadvances.2019000362), *Blood Advances:* Butyrogenic bacteria after acute graft-versus-host disease (GVHD) are associated with development of steroid-refractory GVHD
2. [Payen et al. (2020)](https://doi.org/10.1182/bloodadvances.2020001531), *Blood Advances:* Functional and phylogenetic alterations in gut microbiome are linked to graft-versus-host disease severity
3. [Liao et al. (2021)](https://doi.org/10.1038/s41597-021-00860-8), *Scientific Data:* Compilation of longitudinal microbiota data and hospitalome from hematopoietic cell transplantation patients
4. [Bolyen et al. (2019)](https://doi.org/10.1038/s41587-019-0209-9), *Nature Biotechnology:* Reproducible, interactive, scalable and extensible microbiome data science using QIIME 2
5. [Di Tommaso et al. (2017)](https://doi.org/10.1038/nbt.3820), *Nature Biotechnology:* Nextflow enables reproducible computational workflows
