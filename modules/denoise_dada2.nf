process DENOISE_DADA2 {
    input:
    path fastq_qza
    val read_type
    val trunc_len
    val trunc_q

    output:
    path "denoise_dada2/table.qza",                    emit: table
    path "denoise_dada2/representative_sequences.qza", emit: rep_seqs
    path "denoise_dada2/denoising_stats.qza",          emit: stats

    script:
    """
    echo 'Denoising with DADA2...'

    if [ "${read_type}" = "single" ]; then
        trunc_cmd="--p-trunc-len ${trunc_len}"
    elif [ "${read_type}" = "paired" ]; then
        trunc_cmd="--p-trunc-len-f ${trunc_len} --p-trunc-len-r ${trunc_len}"
    fi

    qiime dada2 denoise-${read_type} \
        --i-demultiplexed-seqs ${fastq_qza} \
        ${trunc_cmd} \
        --p-trunc-q ${trunc_q} \
        --p-n-threads 0 \
        --output-dir denoise_dada2 \
        --verbose
    """
}