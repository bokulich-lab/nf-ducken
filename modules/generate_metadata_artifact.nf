process GENERATE_METADATA_ARTIFACT {
    input:
    path(md_file)

    output:
    path("*.qza")

    script:
    """
    qiime tools import \
        --input-path ${md_file} \
        --output-path ${name}.qza \
        --type 'NCBIAccessionIDs'
    """
}