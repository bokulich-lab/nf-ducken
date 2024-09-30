# nf-ducken 
Workflow to process amplicon meta-analysis data, from either local FASTQs or NCBI accession IDs to taxonomic classification.

## Environment

### Conda

**Note for users with newer Apple processors (M1/M2):** Conda environments require emulation using Rosetta, due to the lack of certain packages for the ARM64 architecture otherwise available with Intel processors. Please follow the [installation and setup instructions here](https://support.apple.com/en-us/HT211861) for details.

Conda environments are available for all processes. Launch a Conda environment-based run using `-profile conda` when running the workflow script.

### Singularity and Docker

Containers are available for all processes. Launch a container-based run with Singularity or Docker using `-profile docker` or `-profile singularity` when running the workflow script.

## Outputs

* `outDir/taxonomy.qza`: Artifact containing frequencies for features collapsed to a given level (default genus).
* `outDir/taxonomy.qzv`: Visualization containing frequencies for features collapsed to a given level (default genus).
* `outDir/feature_table.qza`: Artifact containing table of represented features by sample.
* `outDir/stats/`: Directory containing QC metrics, including FastQC, clustering statistics, denoising statistics, etc.
* `outDir/trace/`: Directory containing runtime metrics with an execution report and a pipeline DAG.

## Process

### Steps: 16S analysis

1. Data import (`qiime tools import`) or FASTQ download (`q2-fondue`)
2. Optional adapter trimming: `q2-cutadapt`
3. Initial quality control and denoising: `q2-dada2`
4. Optional chimera filtering: `q2-vsearch`
5. Closed reference OTU clustering: `q2-vsearch` 
6. Taxonomy classification: `q2-feature-classifier`
7. Collapse to taxon of interest and merge final outputs

### Steps: ITS analysis

Fungal ITS analysis (`params.run_its = true`) deviates from the above 16S workflow. These differences integrate standard recommendations for ITS analysis, and include the following:
* Adapter trimming is run on not only the forward and reverse reads, but also on the reverse complements of both [to account for potential read-through](https://forum.qiime2.org/t/fungal-its-analysis-tutorial/7351).
  * Note in execution: These reverse complement sequences are trimmed in a subsequent step i.e. Cutadapt is run twice for a single sample. Internal analysis demonstrates inconsistent trimming when trimmed in a single step.
* Input references and classifier are required:
  * An input pre-trained classifier is required as a QIIME 2 artifact. This step requires users train their own taxonomic classifier on the UNITE database for fungal ITS sequences, instead of using available classifiers pre-trained on Greengenes or SILVA. A public pre-trained classifier can be downloaded from [GitHub](https://github.com/colinbrislawn/unite-train/releases).
  * Input reference sequences and taxonomy are required as a QIIME 2 artifact to perform feature classification. These are available [from the UNITE team as QIIME 2-compatible files](https://unite.ut.ee/repository.php).

### Execution

```bash
nextflow run /path/to/workflow/main.nf -c run.config -profile conda
```

By default, workflow inputs may be entered as TSV or FASTQ files; the workflow is designed to generate input QIIME 2 artifacts using the import/download processes. This behavior is controlled by the `generate_input` parameter, set to `true` by default.

To use an already-created input QIIME 2 artifact, the user should set `params.generate_input` to `false` and specify the path to the input artifact using the `params.input_artifact` parameter. For example:

```bash
--generate_input false --input_artifact "path/to/input_artifact"
```
