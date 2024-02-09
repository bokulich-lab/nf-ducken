# nf-16s-pipe
Workflow to process amplicon meta-analysis data, from either local FASTQs or NCBI accession IDs to taxonomic classification.

![Pipeline DAG](assets/images/pipeline_dag.png)

## Environment

### Conda

**Note for users with newer Apple processors (M1/M2):** Conda environments require emulation using Rosetta, due to the lack of certain packages for the ARM64 architecture otherwise available with Intel processors. Please follow the [installation and setup instructions here](https://support.apple.com/en-us/HT211861) for details.

Conda environments are available for all processes. To customize in run, modify the environment parameters (`params.qiime_conda_env`, `params.fastqc_conda_env`, `params.multiqc_conda_env`, and `params.fondue_conda_env`) in the input configuration file.

Launch a Conda environment-based run using `-profile conda` when running the workflow script.

### Singularity and Docker

Containers are available for all processes. To customize in run, modify the container parameters (`params.qiime_container`, `params.fastqc_container`, `params.multiqc_container`, and `params.fondue_container`) in the input configuration file.

Launch a container-based run with Singularity or Docker using `-profile docker` or `-profile singularity` when running the workflow script.

## Inputs

Unless otherwise noted, these parameters should be under the scope `params` in the `run.config` file.

### Process parameters

Used for initial FASTQ processing.
* `read_type`: FASTQ type, either `"paired"` or `"single"`

Required if running `q2_fondue`:
* `inp_id_file`: Path to TSV file containing NCBI accession IDs for FASTQs to download. File must adhere to [QIIME 2 metadata formatting requirements](https://docs.qiime2.org/2022.2/tutorials/metadata/#metadata-formatting-requirements)
  * **Note:** FASTQ file names starting with non-alphanumeric characters (particularly `#`) are NOT supported. These will throw an error in your workflow!
* `email_address`: email address of user, required for SRA requests via `q2-fondue`

Required if running from local FASTQ files:
* `fastq_manifest`: Path to TSV file mapping sample identifiers to FASTQ absolute file paths; manifest must adhere to [QIIME 2 FASTQ manifest formatting requirements](https://docs.qiime2.org/2022.2/tutorials/importing/#fastq-manifest-formats)

Required if running Cutadapt:
* `primer_file`: Path to TSV file containing forward (and, if applicable, reverse) primers. Each row represents a different primer pair.
* For primer removal:
  * If single-end, one of the following `cutadapt.adapter`, `cutadapt.front`, and `cutadapt.anywhere`: Primer sequence to remove; `cutadapt.front` is recommended for most amplicon sequence runs.
  * If paired-end, one of the following pairs `cutadapt.adapter_f`/`cutadapt.adapter_r`, `cutadapt.front_f`/`cutadapt.front_r`, or `cutadapt.anywhere_f`/`cutadapt.anywhere_r`: Primer sequences to remove; `cutadapt.front_f`/`cutadapt.front_r` are recommended for most amplicon sequence runs.
  * The workflow does not at the moment support linked primers. Additionally, the workflow currently only takes a collection of single-end or paired-end primers, but not a combination of both.

### Bypassing parameter validation:
* To bypass the automated parameter validation, the user should set `params.validate_parameters` to `false` when issuing the execution command.


### Optional user-input parameters

Used for initial FASTQ processing in scope `params.fastq_split`:
* `enabled`: default `null`, determines whether samples will be processed as a batch or individually; either `"True"` or `"False"`
* `method`: default `"sample"`, represents method by which to split input FASTQ file manifest; either `"sample"` or an integer representing the number of split artifacts for processing 
* `suffix`: default `"_split.tsv"`, suffix for split FASTQ manifest files used as intermediates
  
Cutadapt process parameters in scope `params.cutadapt`:
* `num_cores`: default `1`
* `error_rate`: default `0.1`
* `indels`: default `True`
* `times`: default `1`
* `overlap`: default `3`, used for paired-end reads
* `match_read_wildcards`: default `"False"`
* `match_adapter_wildcards`: default `"True"`
* `minimum_length`: default `1`,
* `discard_untrimmed`: default `"True"`; we highly recommend keeping this parameter `"True"` as the Cutadapt process also separates reads by primer sequence!
* `max_error_flag`: default `null`
* `max_n_flag`: default `null`
* `quality_cutoff_5end`: default `0`
* `quality_cutoff_3end`: default `0`
* `quality_base`: default `33`
* Parameters for **single-end runs**:
  * `adapter`: default `null`
  * `front`: default `null`
  * `anywhere`: default `null`
* Parameters for **paired-end runs**:
  * `adapter_f`: default `null`
  * `front_f`: default `null`
  * `anywhere_f`: default `null`
  * `adapter_r`: default `null`
  * `front_r`: default `null`
  * `anywhere_r`: default `null`

DADA2 process parameters in scope `params.dada2`:
* `trunc_q`: default `2`
* `pooling_method`: default `"independent"`
* `chimera_method`: default `"consensus"`
* `min_fold_parent_over_abundance`: default `1.0`
* `num_threads`: default `0`, to use all available cores on system
* `num_reads_learn`: default `1000000`
* `hashed_feature_ids`: default `"True"`
* Parameters for **single-end runs**:
  * `trunc_len`: default `0`
  * `trim_left`: default `0`
  * `max_ee`: default `2.0`
* Parameters for **paired-end runs**:
  * `trunc_len_f`: default `0`
  * `trunc_len_r`: default `0`
  * `trim_left_f`: default `0`
  * `trim_left_r`: default `0`
  * `max_ee_f`: default `2.0`
  * `max_ee_r`: default `2.0`
  * `min_overlap`: default `12`
    
VSEARCH process parameters in scope `params.vsearch`:
* `perc_identity`: default `0.8`
* `strand`: default `"plus"`
* `num_threads`: default `0`, to use a single thread per core

Feature classifier process parameters in scope `params.classifier`:
* `method`: default `"sklearn"`; also accommodates `"blast"` and `"vsearch"`
* Parameters for `sklearn`-based classifier:
  * `reads_per_batch`: default `"auto"`
  * `num_jobs`: default `-1`
  * `pre_dispatch`: default `"2*n_jobs"`
  * `confidence`: default `0.7`
  * `read_orientation`: default `"auto"`
* Parameters shared between BLAST+ and VSEARCH consensus classifiers:
  * `max_accepts`: default `10`
  * `perc_identity`: default `0.8`
  * `query_cov`: default `0.8`
  * `strand`: default `"both"`
  * `min_consensus` default `0.51`
  * `unassignable_label`: default `"Unassigned"`
* Additional parameters for BLAST+ classifier:
  * `evalue`: default `0.001`
* Additional parameters for VSEARCH classifier:
  * `search_exact`: default `"False"`
  * `top_hits_only`: default `"False"`
  * `max_hits`: default `"all"`
  * `max_rejects`: default `"all"`
  * `output_no_hits`: default `"True"`
  * `weak_id`: default `0.0`
  * `num_threads`: default `1`

VSEARCH reference-based chimera identification process parameters in scope `params.uchime_ref`:
* `dn`: default `1.4`
* `min_diffs`: default `3`
* `min_div`: default `0.8`
* `min_h`: default `0.28`
* `xn`: default `8.0`
* `num_threads`: default `1`

Additional process parameters:
* `taxa_level`: default `5`, collapsing taxonomic classifications to genus; used in `qiime taxa collapse`
* `phred_offset`: default `33`; used in FASTQ import if using local FASTQs
* `vsearch_chimera`: default `"False"`

### Reference input parameters
Reference files if available locally; otherwise, defaults will be downloaded from the [QIIME 2 data resources page](https://docs.qiime2.org/2022.2/data-resources/):
* `otu_ref_file`: default `null`, downloading pre-formatted files from the [SILVA 138 SSURef NR99 full-length sequences](https://data.qiime2.org/2022.2/common/silva-138-99-seqs.qza); used in closed-reference OTU clustering with VSEARCH
* `trained_classifier`: default `null`, downloading [naive Bayes taxonomic classifiers trained on SILVA 138 99% OTUs 
full-length sequences](https://data.qiime2.org/2022.2/common/silva-138-99-nb-classifier.qza); used in taxonomy classification
* `taxonomy_ref_file`: default `null`, downloading pre-formatted file from the [SILVA 138 SSURef NR99 full-length taxonomy](https://data.qiime2.org/2022.2/common/silva-138-99-tax.qza); used in `q2-feature-classifier` if running with BLAST+

For containerization:
* `qiime_release`: default `"2023.2"`, used to specify param `qiime_container` to particular QIIME version
* `qiime_container`: default `"quay.io/qiime2/core:${params.qiime_release}"`; location of QIIME container used for workflow; if running on platforms without Internet, point to a valid .sif file. **Note that local files must be prefixed with `file://`;** triple `/` denotes absolute filepaths.
* `qiime_conda_env`: default `"${baseDir}/assets/qiime2-2023.2-py38-${sys_abbreviation}.yml"`
* `fastqc_release`: default `"v0.11.9_cv8"`, used to specify param `fastqc_container` to particular FastQC image version
* `fastqc_container`: default `"biocontainers:fastqc"`; location of Docker container used for FastQC processes
* `fastqc_conda_env`: default `"bioconda::fastqc"`
* `fondue_release`: default `"2023.2-ps"`, used to specify param `fondue_container` to particular q2-fondue image version
* `fondue_container`: default `"linathekim/q2-fondue:${fondue_release}"`
  * **Note:** The standard environment for `q2-fondue` will not work with Nextflow out of the box. The image requires installation of `procps` (available with `apt-get`) for interactions with Nextflow. These are denoted with the suffix `-ps` on DockerHub.
* `fondue_conda_env`: default `"${baseDir}/assets/q2-fondue-2023.2-${sys-abbreviation}.yml"`
* `multiqc_release`: default `"v1.18"`
* `multiqc_container`: default `"ewels/multiqc:${multiqc_release}"`
* `multiqc_conda_env`: default `"bioconda::multiqc"`

### Additional configurations

These run configurations fall under non-`param` scopes listed below.

Reporting with Nextflow Tower (scope `tower`):
* `enabled`: default `false`, allowing workflow metrics to be reported in the Nextflow Tower interface
* `accessToken`: user token for Nextflow Tower reporting; required if running Nextflow Tower, unless `TOWER_ACCESS_TOKEN` has otherwise been defined in the runtime environment

Execution parameters (scope `process`):
* `executor`: default `"local"`, resource manager to run workflow on; options include `"slurm"`, `"sge"`, `"awsbatch"`, and `"google-lifesciences"`
* `withLabel:container_qiime2.container`: default `${params.qiime_container}`, but can be replaced with location of local container containing QIIME 2 core distribution

### Parameters used when launching workflow from intermediate steps

To skip processes through DADA2, if using pre-denoised feature tables and sequences:
* `denoised_table`: Path to QIIME 2 artifact containing a denoised feature table
* `denoised_seqs`: Path to QIIME 2 artifact containing denoised sequences corresponding with the above feature table

## Outputs

* `outDir/taxonomy.qza`: Artifact containing frequencies for features collapsed to a given level (default genus).
* `outDir/taxonomy.qzv`: Visualization containing frequencies for features collapsed to a given level (default genus).
* `outDir/feature_table.qza`: Artifact containing table of represented features by sample.
* `outDir/stats/`: Directory containing QC metrics, including FastQC, clustering statistics, denoising statistics, etc.
* `outDir/trace/`: Directory containing runtime metrics with an execution report and a pipeline DAG.

## Process

### Steps

1. Data import (`qiime tools import`) or FASTQ download (`q2-fondue`)
2. Optional adapter trimming: `q2-cutadapt`
3. Initial quality control and denoising: `q2-dada2`
4. Optional chimera filtering: `q2-vsearch`
5. Closed reference OTU clustering: `q2-vsearch` 
6. Taxonomy classification: `q2-feature-classifier`
7. Collapse to taxon of interest and merge final outputs

### Execution

```bash
nextflow run /path/to/workflow/main.nf -c run.config -profile conda
```
