# nf-16s-pipe
Workflow to process amplicon meta-analysis data, from NCBI accession IDs to taxonomic diversity metrics.

## Inputs

* NCBI accession IDs, as a newline-delimited text file

## Outputs

## Process

1. Metadata pre-processing: `qiime tools import`
2. FASTQ retrieval: `q2-fondue`
3. Initial quality control: `q2-dada2`
4. Dereplication and closed reference OTU clustering: `q2-vsearch` 
