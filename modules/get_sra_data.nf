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
    file "sra_download/*.qza"

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