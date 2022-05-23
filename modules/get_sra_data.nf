process GENERATE_ID_ARTIFACT {
    input:
    path inp_id_file

    output:
    path "accession_id.qza"

    when:
    start_process == "id_import"

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
    val email
    file id_qza

    output:
    path "sra_download/failed_runs.qza",  emit: failed
    path "sra_download/metadata.qza",     emit: metadata
    path "sra_download/paired_reads.qza", emit: paired
    path "sra_download/single_reads.qza", emit: single

    when:
    start_process == "id_import"

    script:
    """
    echo 'Retrieving data from SRA using q2-fondue...'

    qiime fondue get-all \
        --i-accession-ids ${id_qza} \
        --p-email ${email} \
        --p-n-jobs 4 \
        --output-dir sra_download \
        --verbose
    """
}

process CHECK_FASTQ_TYPE {
    label "singularity_qiime2"

    input:
    val read_type
    path fq_qza

    output:
    path "${fq_qza}"

    script:
    """
    echo 'Checking whether downloaded FASTQs consist of read type ${read_type}...'

    qiime tools export \
        --input-path ${fq_qza} \
        --output-path .

    bash ${workflow.projectDir}/bin/check_fastq_type.sh ${read_type} .
    """
}

process IMPORT_FASTQ {
    label "singularity_qiime2"

    input:
    path fq_manifest

    output:
    path "sequences.qza"

    script:
    read_type_upper = ${val_read_type}.capitalize()

    """
    echo 'Local FASTQs detected. Converting to QIIME artifact...'

    qiime tools import \
        --type 'SampleData[${read_type_upper}EndSequencesWithQuality]' \
        --input-path ${fq_manifest} \
        --input-format ${read_type_upper}EndFastqManifestPhred${val_phred_offset}V2 \
        --output-path sequences.qza
    """
}