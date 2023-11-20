process DENOISE_DADA2 {
    conda "${params.qiime_env_file}"
    label "container_qiime2"
    label "process_local"
    label "error_retry"
    tag "${sample_id}"

    publishDir "${params.outdir}/stats/", pattern: "*_stats.qza"
    afterScript "rm -rf \${PWD}/tmp_denoise"

    input:
    tuple val(sample_id), path(fastq_qza)

    output:
    tuple val(sample_id), path("${sample_id}_table.qza"), path("${sample_id}_representative_sequences.qza"), emit: table_seqs
    path "${sample_id}_denoising_stats.qza",    emit: stats

    script:
    if (params.read_type == "single")
        """
        echo 'Denoising single-end reads with DADA2...'

        export NXF_TEMP=\${PWD}/tmp_denoise
        mkdir \${PWD}/tmp_denoise

        qiime dada2 denoise-${params.read_type} \
            --i-demultiplexed-seqs ${fastq_qza} \
            --p-trunc_len ${params.dada2.trunc_len} \
            --p-trim-left ${params.dada2.trim_left} \
            --p-max-ee ${params.dada2.max_ee} \
            --p-trunc-q ${params.dada2.trunc_q} \
            --p-pooling-method ${params.dada2.pooling_method} \
            --p-chimera-method ${params.dada2.chimera_method} \
            --p-min-fold-parent-over-abundance ${params.dada2.min_fold_parent_over_abundance} \
            --p-n-threads ${params.dada2.num_threads} \
            --p-n-reads-learn ${params.dada2.num_reads_learn} \
            --p-hashed-feature-ids ${params.dada2.hashed_feature_ids} \
            --o-table ${sample_id}_table.qza \
            --o-representative-sequences ${sample_id}_representative_sequences.qza \
            --o-denoising-stats ${sample_id}_denoising_stats.qza \
            --verbose
        """

    else if (params.read_type == "paired")
        """
        echo 'Denoising paired-end reads with DADA2...'

        export NXF_TEMP=\${PWD}/tmp_denoise
        mkdir \${PWD}/tmp_denoise

        qiime dada2 denoise-${params.read_type} \
            --i-demultiplexed-seqs ${fastq_qza} \
            --p-trunc-len-f ${params.dada2.trunc_len_f} \
            --p-trunc-len-r ${params.dada2.trunc_len_r} \
            --p-trim-left-f ${params.dada2.trim_left_f} \
            --p-trim-left-r ${params.dada2.trim_left_r} \
            --p-max-ee-f ${params.dada2.max_ee_f} \
            --p-max-ee-r ${params.dada2.max_ee_r} \
            --p-min-overlap ${params.dada2.min_overlap} \
            --p-trunc-q ${params.dada2.trunc_q} \
            --p-pooling-method ${params.dada2.pooling_method} \
            --p-chimera-method ${params.dada2.chimera_method} \
            --p-min-fold-parent-over-abundance ${params.dada2.min_fold_parent_over_abundance} \
            --p-n-threads ${params.dada2.num_threads} \
            --p-n-reads-learn ${params.dada2.num_reads_learn} \
            --p-hashed-feature-ids ${params.dada2.hashed_feature_ids} \
            --o-table ${sample_id}_table.qza \
            --o-representative-sequences ${sample_id}_representative_sequences.qza \
            --o-denoising-stats ${sample_id}_denoising_stats.qza \
            --verbose
        """
}