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
    tuple val(primer_id), val(primer_seq), path("demux_${primer_id}_seqs.qza")

    script:
    if (params.read_type == "single") {
        """
        echo 'Running Cutadapt to separate single-end sequences by primer...'

        qiime cutadapt demux-single \
            --i-seqs ${fastq_qza} \
            --m-barcodes-file \
            --m-barcodes-column \
            --p-error-rate ${params.cutadapt.demux.error_rate} \
            --p-batch-size ${params.cutadapt.demux.batch_size} \
            --p-minimum-length ${params.cutadapt.demux.minimum_length} \
            --p-cores ${params.cutadapt.demux.num_cores} \
            --o-per-sample-sequences demux_${primer_id}_seqs.qza \
            --o-untrimmed-sequences unmatched_${primer_id}_seqs.qza \
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
            --p-error-rate ${params.cutadapt.demux.error_rate} \
            --p-batch-size ${params.cutadapt.demux.batch_size} \
            --p-minimum-length ${params.cutadapt.demux.minimum_length} \
            --p-mixed-orientation ${params.cutadapt.demux.mixed_orientation} \
            --p-cores ${params.cutadapt.demux.num_cores} \
            --o-per-sample-sequences demux_${primer_id}_seqs.qza \
            --o-untrimmed-sequences unmatched_${primer_id}_seqs.qza \
            --verbose
        """
    }
}

process CUTADAPT_TRIM {
    label "container_qiime2"

    input:
    tuple val(primer_id), val(primer_seq), path(demux_qza)

    output:
    tuple val(primer_id), path("trimmed_${primer_id}_seqs.qza")

    script:
    // Optional flags
    if (params.cutadapt.trim.max_expected_errors) {
        max_error_flag = "--p-max-expected-errors ${params.cutadapt.trim.max_expected_errors}"
    } else {
        max_error_flag = ""
    }

    if (params.cutadapt.trim.max_n) {
        max_n_flag = "--p-max-n ${params.cutadapt.trim.max_n}"
    } else {
        max_n_flag = ""
    }

    // Command
    if (params.read_type == "single") {
        """
        echo 'Running Cutadapt to trim primers from single-end sequences...'

        qiime cutadapt trim-single \
            --i-demultiplexed-sequences ${demux_qza} \
            --p-cores ${params.cutadapt.trim.num_cores} \
            --p-adapter \
            --p-front \
            --p-anywhere \
            --p-error-rate ${params.cutadapt.trim.error_rate} \
            --p-indels ${params.cutadapt.trim.indels} \
            --p-times ${params.cutadapt.trim.times} \
            --p-overlap ${params.cutadapt.trim.overlap} \
            --p-match-read-wildcards ${params.cutadapt.trim.match_read_wildcards} \
            --p-match-adapter-wildcards ${params.cutadapt.trim.match_adapter_wildcards} \
            --p-minimum-length ${params.cutadapt.trim.minimum_length} \
            --p-discard-untrimmed ${params.cutadapt.trim.discard_umtrimmed} \
            ${max_error_flag} \
            ${max_n_flag} \
            --p-quality-cutoff-5end ${params.cutadapt.trim.quality_cutoff_5end} \
            --p-quality-cutoff-3end ${params.cutadapt.trim.quality_cutoff_3end} \
            --p-quality-base ${params.cutadapt.trim.quality_base} \
            --o-trimmed-sequences trimmed_${primer_id}_seqs.qza \
            --verbose
        """
    } else if (params.read_type == "paired") {
        """
        echo 'Running Cutadapt to trim primers from paired-end sequences...'

        qiime cutadapt trim-paired \
            --i-demultiplexed-sequences ${demux_qza} \
            --p-cores ${params.cutadapt.trim.num_cores} \
            --p-adapter-f \
            --p-front-f \
            --p-anywhere-f \
            --p-adapter-r \
            --p-front-r \
            --p-anywhere-r \
            --p-error-rate ${params.cutadapt.trim.error_rate} \
            --p-indels ${params.cutadapt.trim.indels}\
            --p-times ${params.cutadapt.trim.times} \
            --p-overlap ${params.cutadapt.trim.overlap} \
            --p-match-read-wildcards ${params.cutadapt.trim.match_read_wildcards} \
            --p-match-adapter-wildcards ${params.cutadapt.trim.match_adapter_wildcards} \
            --p-minimum-length ${params.cutadapt.minimum_length} \
            --p-discard-untrimmed ${params.cutadapt.discard_untrimmed} \
            ${max_error_flag} \
            ${max_n_flag} \
            --p-quality-cutoff-5end ${params.cutadapt.trim.quality_cutoff_5end} \
            --p-quality-cutoff-3end ${params.cutadapt.trim.quality_cutoff_3end} \
            --p-quality-base ${params.cutadapt.trim.quality_base} \
            --o-trimmed-sequences trimmed_${primer_id}_seqs.qza \
            --verbose
        """
    }
}