process GENERATE_ID_ARTIFACT {
    input:
    path inp_id_file

    output:
    file "*.qza"

    script:
    """
    echo ${inp_id_file}
    qiime tools import \
        --input-path ${inp_id_file} \
        --output-path accession_id.qza \
        --type 'NCBIAccessionIDs'
    """
}