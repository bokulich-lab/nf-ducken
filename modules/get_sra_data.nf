process GENERATE_ID_ARTIFACT {
    input:
    path inp_id_file

    output:
    file "accession_id.qza"

    script:
    """
    echo \"${inp_id_file} has been detected.\"
    echo \"Generating QIIME artifact of accession IDs...\"

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
    echo \"Retrieving data from SRA using q2-fondue...\"

    qiime fondue get-all \
        --i-accession-ids ${id_qza} \
        --p-email ${email} \
        --p-n-jobs 4 \
        --output-dir sra_download \
        --verbose
    """
}