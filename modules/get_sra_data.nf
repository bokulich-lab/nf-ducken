process GENERATE_ID_ARTIFACT {
    input:
    path inp_id_file

    output:
    path "accession_id.qza"

    when:
    start_process = "id_import"

    script:
    """
    echo '${inp_id_file} has been detected.'
    echo 'Generating QIIME artifact of accession IDs...'

    qiime tools import \
        --input-path ${inp_id_file} \
        --output-path accession_id.qza \
        --type 'NCBIAccessionIDs'
    """
}

process GET_SRA_DATA {
    input:
    path id_qza

    output:
    path "sra_download/failed_runs.qza",  emit: failed
    path "sra_download/metadata.qza",     emit: metadata
    path "sra_download/paired_reads.qza", emit: paired
    path "sra_download/single_reads.qza", emit: single

    when:
    start_process = "id_import"

    script:
    """
    echo 'Retrieving data from SRA using q2-fondue...'

    qiime fondue get-all \
        --i-accession-ids ${id_qza} \
        --p-email ${params.email} \
        --p-n-jobs 4 \
        --output-dir sra_download \
        --verbose
    """
}

process IMPORT_FASTQ {
    label "container_qiime2"
    errorStrategy "ignore"

    input:
    path fq_manifest

    output:
    path "sequences.qza"

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