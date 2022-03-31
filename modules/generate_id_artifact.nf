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