process MULTIQC_STATS {
    label "container_multiqc"
    publishDir "${params.outdir}/stats/", mode: 'copy'

    input:
    path fastqc
    path cutadapt

    output:
    path "multiqc/*"

    script:
    """
    echo 'Create statistics using MultiQC...'
    multiqc . --outdir multiqc
    """

}
