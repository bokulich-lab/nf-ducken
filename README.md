# nf-16s-pipe
Workflow to process amplicon meta-analysis data, from NCBI accession IDs to taxonomic diversity metrics.

## Environment

### Conda environments

Create a new `conda` environment with dependencies for the latest QIIME 2 release:
```
conda create -y -n nf-16s-pipe \
    -c qiime2 -c conda-forge -c bioconda -c defaults \
    qiime2 q2cli q2-types "entrezpy>=2.1.2" "tqdm>=4.62.3" xmltodict pyzotero nextflow
```

Install `q2-fondue` and required dependencies:
```
curl -sLH 'Accept: application/vnd.github.v3.raw' https://api.github.com/repos/bokulich-lab/q2-fondue/contents/install-sra-tools.sh > install-sra-tools.sh

chmod +x install-sra-tools.sh
bash install-sra-tools.sh

rm install-sra-tools.sh

pip install git+https://github.com/bokulich-lab/q2-fondue.git

qiime dev refresh-cache
```

### Singularity

Singularity container integration in progress. To customize in run, modify the `params.qiime_container` in the input configuration file.

If running in closed systems, the QIIME 2 Docker container can be built and saved into an .sif file by running: `sudo singularity build qiime2-2022.2.sif docker://quay.io/qiime2/core:2022.2`.

Internally, the latest QIIME 2 container can be found at the following locations:
* On the SPHN container registry (accessible from Leonhard Med): container-registry.dcc.sib.swiss
* As an .sif file on Leonhard Med: `/cluster/work/saga/singularity/qiime2-2022.2.sif`

## Inputs

Unless otherwise noted, these parameters should be under the scope `params` in the `run.config` file.

### Process parameters

Used for file download and FASTQ processing.
* `inp_id_file`: path to TSV file containing NCBI accession IDs for FASTQs to download. File must adhere to [QIIME 2 metadata formatting requirements](https://docs.qiime2.org/2022.2/tutorials/metadata/#metadata-formatting-requirements)
* `email_address`: email address of user, required for SRA requests via `q2-fondue`
* `read_type`: FASTQ type, either`"paired"` or `"single"`
* `fastq_split`: default `null`, determines whether samples will be processed as a batch or individually.

### Optional user-input parameters

DADA2 process parameters in scope `params.dada2`:
  * `trunc_q`: default `2`, reads are truncated at the first instance of a quality score less than or equal to this value
  * `pooling_method`: default `independent`
  * `chimera_method`: default `consensus`
  * `min_fold_parent_over_abundance`: default `1.0`
  * `num_threads`: default `1`
  * `num_reads_learn`: default `1000000`
  * `hashed_feature_ids`: default `"True"`
  * Parameters for **single-end runs**, in scope `params.dada2["single"]`:
    * `trunc_len`: default `0`
    * `trim_left`: default `0`
    * `max_ee`: default `2.0`
  * Parameters for **paired-end runs**, in scope `params.dada2["paired"]`:
    * `trunc_len_f`: default `0`
    * `trunc_len_r`: default `0`
    * `trim_left_f`: default `0`
    * `trim_left_r`: default `0`
    * `max_ee_f`: default `2.0`
    * `max_ee_r`: default `2.0`
    * `min_overlap`: default `12`
  
Additional process parameters:
  * `taxa_level`: default `5`, collapsing taxonomic classifications to genus; used in `qiime taxa collapse`
  * `phred_offset`: default `33`; used in FASTQ import if using local FASTQs
  * `cluster_identity`: default `0.8`; used as identity threshold in VSEARCH for closed reference clustering

### Reference input parameters
Reference files if available locally; otherwise, defaults will be downloaded from the [QIIME 2 data resources page](https://docs.qiime2.org/2022.2/data-resources/):
* `otu_ref_file`: default `null`, downloading pre-formatted files from the [SILVA 138 SSURef NR99 full-length sequences](https://data.qiime2.org/2022.2/common/silva-138-99-seqs.qza); used in closed-reference OTU clustering with VSEARCH
* `trained_classifier`: default `null`, downloading [naive Bayes taxonomic classifiers trained on SILVA 138 99% OTUs 
full-length sequences](https://data.qiime2.org/2022.2/common/silva-138-99-nb-classifier.qza); used in taxonomy classification
* `qiime_release`: default `"2022.2"`, used to specify param `qiime_container` to particular QIIME version
* `qiime_container`: default `"quay.io/qiime2/core:${params.qiime_release}"`; location of QIIME container used for workflow; if running on platforms without Internet, point to a valid .sif file. **Note that local files must be prefixed with `file://`;** triple `/` denotes absolute filepaths.

### Additional configurations

These run configurations fall under non-`param` scopes listed below.

Reporting with Nextflow Tower (scope `tower`):
* `enabled`: default `false`, allowing workflow metrics to be reported in the Nextflow Tower interface
* `accessToken`: user token for Nextflow Tower reporting; required if running Nextflow Tower, unless `TOWER_ACCESS_TOKEN` has otherwise been defined in the runtime environment

Execution parameters (scope `process`):
* `executor`: default `"local"`, resource manager to run workflow on; options include `"slurm"`, `"sge"`, `"awsbatch"`, and `"google-lifesciences"`
* `withLabel:singularity_qiime2.container`: default `${params.qiime_container}`, but can be replaced with location of local container containing QIIME 2 core distribution

### Parameters used for intermediate process skipping

To skip SRA FASTQ retrieval, if using local FASTQs:
* `fastq_manifest`: Path to TSV file mapping sample identifiers to FASTQ absolute file paths; manifest must adhere to [QIIME 2 FASTQ manifest formatting requirements](https://docs.qiime2.org/2022.2/tutorials/importing/#fastq-manifest-formats)
* `phred_offset`: default `33`, should be either `33` or `64`; integer indicating quality score encoding scheme for FASTQs

To skip processes through DADA2, if using pre-denoised feature tables and sequences:
* `denoised_table`: Path to QIIME 2 artifact containing a denoised feature table
* `denoised_seqs`: Path to QIIME 2 artifact containing denoised sequences corresponding with the above feature table

## Outputs

* `outDir/taxa/collapsed_table.qza`: Artifact containing frequencies for features collapsed to a given level (default genus).

## Process

### Steps

1. Metadata pre-processing: `qiime tools import`
2. FASTQ retrieval: `q2-fondue`
3. Initial quality control: `q2-dada2`
4. Closed reference OTU clustering: `q2-vsearch` 
5. Taxonomy classification: `q2-feature-classifier`

### Execution

```bash
nextflow run /path/to/workflow/main.nf -c run.config
```