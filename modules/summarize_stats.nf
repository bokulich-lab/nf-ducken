// Process to generate MultiQC statistics
process MULTIQC_STATS{
    label "container_multiqc"
    publishDir "${baseDir}/${params.outdir}/stats/", mode: 'copy'

    input:
    path fastqc_dep
    path cutadapt_dep

    output:
    path "multiqc_out/*"

    script:
    """
    echo 'Create statistics using MultiQC...'
    multiqc ${baseDir}/${params.outdir}/stats --outdir multiqc_out
    """

}
