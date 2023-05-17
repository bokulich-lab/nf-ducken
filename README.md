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

A Singularity container is available for all processes except for sequence downloads using `q2-fondue`. To customize in run, modify the `params.qiime_container` in the input configuration file.

## Inputs

Unless otherwise noted, these parameters should be under the scope `params` in the `run.config` file.

### Process parameters

Used for initial FASTQ processing.

* `read_type`: FASTQ type, either `"paired"` or `"single"`

Required if running `q2_fondue`:
* `inp_id_file`: path to TSV file containing NCBI accession IDs for FASTQs to download. File must adhere to [QIIME 2 metadata formatting requirements](https://docs.qiime2.org/2022.2/tutorials/metadata/#metadata-formatting-requirements)
  * **Note:** FASTQ file names starting with non-alphanumeric characters (particularly `#`) are NOT supported. These will throw an error in your workflow!
* `email_address`: email address of user, required for SRA requests via `q2-fondue`

Required if running from local FASTQ files:
* `fastq_manifest`: Path to TSV file mapping sample identifiers to FASTQ absolute file paths; manifest must adhere to [QIIME 2 FASTQ manifest formatting requirements](https://docs.qiime2.org/2022.2/tutorials/importing/#fastq-manifest-formats)

### Optional user-input parameters

Used for initial FASTQ processing in scope `params.fastq_split`:
* `enabled`: default `null`, determines whether samples will be processed as a batch or individually; either `"True"` or `"False"`
* `method`: default `"sample"`, represents method by which to split input FASTQ file manifest; either `"sample"` or an integer representing the number of split artifacts for processing 
* `suffix`: default `"_split.tsv"`, suffix for split FASTQ manifest files used as intermediates
  
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
* `qiime_release`: default `"2022.2"`, used to specify param `qiime_container` to particular QIIME version
* `qiime_container`: default `"quay.io/qiime2/core:${params.qiime_release}"`; location of QIIME container used for workflow; if running on platforms without Internet, point to a valid .sif file. **Note that local files must be prefixed with `file://`;** triple `/` denotes absolute filepaths.
* `pandas_release`: default `"1.4.2"`, used to specify param `pandas_container` to particular `pandas` version
* `pandas_container`: default `"docker://amancevice/pandas:${params.pandas_release}-slim"`; location of `pandas` container used for workflow

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

* `outDir/merged_taxonomy.qza`: Artifact containing frequencies for features collapsed to a given level (default genus).
* `outDir/merged_taxonomy.qzv`: Visualization containing frequencies for features collapsed to a given level (default genus).
* `outDir/merged_feature_table.qza`: Artifact containing table of represented features by sample.

## Process

### Steps

1. Metadata pre-processing: `qiime tools import`
2. FASTQ retrieval: `q2-fondue`
3. Initial quality control: `q2-dada2`
4. Closed reference OTU clustering: `q2-vsearch` 
5. Taxonomy classification: `q2-feature-classifier`
6. Collapse to taxon of interest and merge final outputs

### Execution

```bash
nextflow run /path/to/workflow/main.nf -c run.config
```
