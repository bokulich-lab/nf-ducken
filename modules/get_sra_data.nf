process GET_SRA_DATA {
    input:
    tuple val(email), file(id_qza)

    output:
    file "sra_download/*.qza"

    script:
    """
    qiime fondue get-all \
        --m-accession-ids-file ${id_qza} \
        --p-email ${email} \
        --p-n-jobs 4 \
        --output-dir sra_download \
        --verbose
    """
}