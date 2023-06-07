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
        echo 'Running Cutadapt to separate single-end sequences by primer...'

        qiime cutadapt demux-single \
            --i-seqs ${fastq_qza} \
            --m-barcodes-file \
            --m-barcodes-column \
            --p-error-rate \
            --p-batch-size \
            --p-minimum-length \
            --p-cores \
            --o-per-sample-sequences \
            --o-untrimmed-sequences \
            --verbose
        """
    } else if (params.read_type == "paired") {
        """
        echo 'Running Cutadapt to separate paired-end sequences by primer...'

        qiime cutadapt demux-paired \
            --i-seqs ${fastq_qza} \
            --m-forward-barcodes-file \
            --m-forward-barcodes-column \
            --m-reverse-barcodes-file \
            --m-reverse-barcodes-column \
            --p-error-rate \
            --p-batch-size \
            --p-minimum-length \
            --p-mixed-orientation \
            --p-cores \
            --o-per-sample-sequences \
            --o-untrimmed-sequences \
            --verbose
        """
    }
}

process CUTADAPT_TRIM {
    label "container_qiime2"

    input:
    tuple val(primer), path(demux_qza)

    output:
    tuple val(primer), path("seqs_${primer}.qza")

    script:
    if (params.read_type == "single") {
        """
        echo 'Running Cutadapt to trim primers from single-end sequences...'

        qiime cutadapt trim-single \
            --i-demultiplexed-sequences ${demux_qza} \
            --p-cores \
            --p-adapter \
            --p-front ${primer} \
            --p-anywhere \
            --p-error-rate \
            --p-indels \
            --p-times \
            --p-overlap \
            --p-match-read-wildcards \
            --p-match-adapter-wildcards \
            --p-minimum-length \
            --p-discard-untrimmed \
            --p-max-expected-errors \
            --p-max-n \
            --p-quality-cutoff-5end \
            --p-quality-cutoff-3end \
            --p-quality-base \
            --o-trimmed-sequences seqs_${primer}.qza \
            --verbose
        """
    } else if (params.read_type == "paired") {
        """
        echo 'Running Cutadapt to trim primers from paired-end sequences...'

        qiime cutadapt trim-paired \
            --i-demultiplexed-sequences ${demux_qza} \
            --p-cores \
            --p-adapter-f \
            --p-front-f \
            --p-anywhere-f \
            --p-adapter-r \
            --p-front-r \
            --p-anywhere-r \
            --p-error-rate \
            --p-indels \
            --p-times \
            --p-overlap \
            --p-match-read-wildcards \
            --p-match-adapter-wildcards \
            --p-minimum-length \
            --p-discard-untrimmed \
            --p-max-expected-errors \
            --p-max-n \
            --p-quality-cutoff-5end \
            --p-quality-cutoff-3end \
            --p-quality-base \
            --o-trimmed-sequences seqs_${primer}.qza \
            --verbose
        """
    }
}