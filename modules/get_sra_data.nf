process GENERATE_ID_ARTIFACT {
    label "container_fondue"
    tag "${set_id}"

    input:
    tuple val(set_id), path(inp_id_file)

    output:
    tuple val(set_id), path("id.qza")

    script:
    """
    echo '${inp_id_file} has been detected.'
    echo 'Generating QIIME artifact of accession IDs...'

    qiime tools import \
        --input-path ${inp_id_file} \
        --output-path id.qza \
        --type 'NCBIAccessionIDs'
    """
}

process GET_SRA_DATA {
    label "container_fondue"
    tag "${set_id}"

    input:
    tuple val(set_id), path(id_qza)

    output:
    tuple val(set_id), path("sra_download/failed_runs.qza"),  emit: failed
    tuple val(set_id), path("sra_download/paired_reads.qza"), emit: paired
    tuple val(set_id), path("sra_download/single_reads.qza"), emit: single

    script:
    """
    echo 'Retrieving data from SRA using q2-fondue...'

    if [ ! -d "$HOME/.ncbi" ]; then
      mkdir $HOME/.ncbi
    fi

    if [ ! -f "$HOME/.ncbi/user-settings.mkfg" ]; then
      printf '/LIBS/GUID = "%s"\n' `uuidgen` > $HOME/.ncbi/user-settings.mkfg
    fi

    qiime fondue get-sequences \
        --i-accession-ids ${id_qza} \
        --p-email ${params.email_address} \
        --output-dir sra_download \
        --verbose
    """
}

process IMPORT_FASTQ {
    label "container_qiime2"
    errorStrategy "ignore"
    tag "${set_id}"

    input:
    tuple val(set_id), path(fq_manifest)

    output:
    tuple val(set_id), path("sequences.qza")

    script:
    read_type_upper = params.read_type.capitalize()
    if (params.read_type == "paired") {
        semantic_type = "SampleData[PairedEndSequencesWithQuality]"
    } else {
        semantic_type = "SampleData[SequencesWithQuality]"
    }

    """
    echo 'Local FASTQs detected. Converting to QIIME artifact...'

    qiime tools import \
        --type '${semantic_type}' \
        --input-path ${fq_manifest} \
        --input-format ${read_type_upper}EndFastqManifestPhred${params.phred_offset}V2 \
        --output-path sequences.qza
    """
}

process SPLIT_FASTQ_MANIFEST {
    label "container_pandas"

    input:
    tuple val(set_id), path(fq_manifest)

    output:
    path "*${params.fastq_split.suffix}"

    script:
    """
    echo 'Splitting FASTQ manifest to process FASTQ files individually...'
    python ${workflow.projectDir}/bin/split_manifest.py \
        --input_manifest ${fq_manifest} \
        --output_dir . \
        --suffix ${params.fastq_split.suffix} \
        --split_method ${params.fastq_split.method}
    """
}