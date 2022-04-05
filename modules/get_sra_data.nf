process GENERATE_ID_ARTIFACT {
    input:
    path inp_id_file

    output:
    file "accession_id.qza"

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
    file "sra_download/failed_runs.qza" into fondue_failed_runs
    file "sra_download/metadata.qza" into fondue_metadata
    file "sra_download/paired_reads.qza" into fondue_pe_reads
    file "sra_download/single_reads.qza" into fondue_se_reads

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
    input:
    val read_type
    file fq_qza

    script:
    """
    echo 'Checking whether downloaded FASTQs consist of read type ${read_type}...'

    qiime tools export \
        --input-path ${fq_qza} \
        --output-path .

    bash ${workflow.projectDir}/bin/check_fastq_type.sh ${read_type} ${pwd}
    exit_code=$?

    [ ${exit_code} -eq 0 ] |
    && echo 'Downloaded FASTQs correspond to input read type.' ||
    echo 'ERROR: Mismatch between downloaded FASTQs and input read type.'; false
    """
}