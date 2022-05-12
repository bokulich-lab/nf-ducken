# nf-16s-pipe
Workflow to process amplicon meta-analysis data, from NCBI accession IDs to taxonomic diversity metrics.

## Environment

Singularity containers in progress.

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

## Inputs

### End-to-end configuration 

* `inp_id_file`: Path to TSV file containing NCBI accession IDs for FASTQs to download. File must adhere to [QIIME 2 metadata formatting requirements](https://docs.qiime2.org/2022.2/tutorials/metadata/#metadata-formatting-requirements)
* `email_address`: Email address of user, required for SRA requests via `q2-fondue`
* `read_type`: FASTQ type, either`"paired"` or `"single"`

### Optional user-input parameters

Process parameters:
* `trunc_len`: default `0`; used in DADA2, position at which sequences should be truncated due to decrease in quality
* `trunc_q`: default `2`; used in DADA2, reads are truncated at the first instance of a quality score less than or equal to this value
* `taxa_level`: default `5`, collapsing taxonomic classifications to genus; used in `qiime taxa collapse`
* `phred_offset`: default `33`; used in FASTQ import if using local FASTQs
* `cluster_identity`: default TBD; used as threshold in VSEARCH for closed reference clustering

Reference files if available locally; otherwise, defaults will be downloaded from the [QIIME 2 data resources page](https://docs.qiime2.org/2022.2/data-resources/):
* `otu_ref_file`: default `null`, downloading pre-formatted files from the [SILVA 138 SSURef NR99 full-length sequences](https://data.qiime2.org/2022.2/common/silva-138-99-seqs.qza); used in closed-reference OTU clustering with VSEARCH
* `trained_classifier`: default `null`, downloading [naive Bayes taxonomic classifiers trained on SILVA 138 99% OTUs full-length sequences](https://data.qiime2.org/2022.2/common/silva-138-99-nb-classifier.qza); used in taxonomy classification 

### Parameters used for intermediate process skipping

To skip SRA FASTQ retrieval, if using local FASTQs:
* `fastq_manifest`: Path to TSV file mapping sample identifiers to FASTQ absolute file paths; manifest must adhere to [QIIME 2 FASTQ manifest formatting requirements](https://docs.qiime2.org/2022.2/tutorials/importing/#fastq-manifest-formats)
* `phred_offset`: default `33`, should be either `33` or `64`; integer indicating quality score encoding scheme for FASTQs

To skip processes through DADA2, if using pre-denoised feature tables and sequences:
* `denoised_table`: Path to QIIME 2 artifact containing a denoised feature table
* `denoised_seqs`: Path to QIIME 2 artifact containing denoised sequences corresponding with the above feature table

## Outputs

## Process

1. Metadata pre-processing: `qiime tools import`
2. FASTQ retrieval: `q2-fondue`
3. Initial quality control: `q2-dada2`
4. Closed reference OTU clustering: `q2-vsearch` 
5. Taxonomy classification: `q2-feature-classifier`