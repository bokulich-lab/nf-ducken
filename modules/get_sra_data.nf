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