process CHECK_FASTQ_TYPE {
    label "container_qiime2"

    input:
    path fq_qza

    output:
    path "${fq_qza}",  emit: qza
    path "*.fastq.gz", emit: fqs

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
    path fqs

    output:
    path "fastqc/*"

    script:
    """
    echo 'Running FastQC on FASTQ files for quality control...'

    mkdir fastqc
    fastqc ${fqs} --outdir=fastqc/
    """
}

process CUTADAPT_DEMUX {
    label "container_qiime2"

    input:
    path fastq_qza

    output:
    tuple val(primer), path(demux_qza)

    script:
    if (params.read_type == "single") {
        """
        echo 'Running Cutadapt to separate ${params.read_type}-end sequences by primer...'
        """
    } else if (params.read_type == "paired") {
        """
        echo 'Running Cutadapt to separate ${params.read_type}-end sequences by primer...'
        """
    }
}

process CUTADAPT_TRIM {
    label "container_qiime2"

    input:
    tuple val()

    script:
    if (params.read_type == "single") {
        """
        echo 'Running Cutadapt to trim primers from ${params.read_type}-end sequences...'
        """
    } else if (params.read_type == "paired") {
        """
        echo 'Running Cutadapt to trim primers from ${params.read_type}-end sequences...'
        """
    }
}