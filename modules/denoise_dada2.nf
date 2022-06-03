process DENOISE_DADA2 {
    label "singularity_qiime2"
    label "process_local"
    scratch true

    input:
    path fastq_qza

    output:
    path "denoise_dada2/table.qza",                    emit: table
    path "denoise_dada2/representative_sequences.qza", emit: rep_seqs
    path "denoise_dada2/denoising_stats.qza",          emit: stats

    script:

    if (params.read_type == "single")
        """
        echo 'Denoising with DADA2...'

        qiime dada2 denoise-${params.read_type} \
            --i-demultiplexed-seqs ${fastq_qza} \
            --p-trunc_len ${params.dada2.single.trunc_len} \
            --p-trim-left ${params.dada2.single.trim_left} \
            --p-max-ee ${params.dada2.single.max_ee} \
            --p-trunc-q ${params.dada2.trunc_q} \
            --p-pooling-method ${params.dada2.pooling_method} \
            --p-chimera-method ${params.dada2.chimera_method} \
            --p-min-fold-parent-over-abundance ${params.dada2.min_fold_parent_over_abundance} \
            --p-n-threads ${params.dada2.num_threads} \
            --p-n-reads-learn ${params.dada2.num_reads_learn} \
            --p-hashed-feature-ids ${params.dada2.hashed_feature_ids} \
            --output-dir denoise_dada2 \
            --verbose
        """

    else if (params.read_type == "paired")
        """
        echo 'Denoising with DADA2...'

        qiime dada2 denoise-${params.read_type} \
            --i-demultiplexed-seqs ${fastq_qza} \
            --p-trunc-len-f ${params.dada2.paired.trunc_len_f} \
            --p-trunc-len-r ${params.dada2.paired.trunc_len_r} \
            --p-trim-left-f ${params.dada2.paired.trim_left_f} \
            --p-trim-left-r ${params.dada2.paired.trim_left_r} \
            --p-max-ee-f ${params.dada2.paired.max_ee_f} \
            --p-max-ee-r ${params.dada2.paired.max_ee_r} \
            --p-min-overlap ${params.dada2.paired.min_overlap} \
            --p-trunc-q ${params.dada2.trunc_q} \
            --p-pooling-method ${params.dada2.pooling_method} \
            --p-chimera-method ${params.dada2.chimera_method} \
            --p-min-fold-parent-over-abundance ${params.dada2.min_fold_parent_over_abundance} \
            --p-n-threads ${params.dada2.num_threads} \
            --p-n-reads-learn ${params.dada2.num_reads_learn} \
            --p-hashed-feature-ids ${params.dada2.hashed_feature_ids} \
            --output-dir denoise_dada2 \
            --verbose
        """
}