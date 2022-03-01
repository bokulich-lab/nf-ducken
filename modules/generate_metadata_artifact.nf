process GENERATE_METADATA_ARTIFACT {
    input:
    tuple val(name), path(md_file)

    output:
    tuple val(name), path("*.qza")

    script:
    """
    qiime tools import \
        --input-path ${md_file} \
        --output-path ${name}.qza \
        --type 'NCBIAccessionIDs'
    """
}