process CHECK_FASTQ_TYPE {
    label "container_qiime2"
    tag "${sample_id}"

    input:
    tuple val(sample_id), path(fq_qza)

    output:
    tuple val(sample_id), path("${fq_qza}"),  emit: qza
    tuple val(sample_id), path("*.fastq.gz"), emit: fqs

    script:
    """
    echo 'Checking whether downloaded FASTQs consist of read type ${params.read_type}...'

    qiime tools export \
        --input-path ${fq_qza} \
        --output-path .

    bash ${workflow.projectDir}/bin/check_fastq_type.sh ${params.read_type} .
    """
}

process RUN_FASTQC {
    label "container_fastqc"
    publishDir "${params.outdir}/stats/fastqc/"

    input:
    tuple val(sample_id), path(fqs)

    output:
    path "fastqc/*"

    script:
    """
    echo 'Running FastQC on FASTQ files for quality control...'

    mkdir fastqc
    fastqc ${fqs} --outdir=fastqc/
    """
}