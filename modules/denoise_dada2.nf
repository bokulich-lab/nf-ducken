process DENOISE_DADA2 {
    label "singularity_qiime2"

    input:
    path fastq_qza

    output:
    path "denoise_dada2/table.qza",                    emit: table
    path "denoise_dada2/representative_sequences.qza", emit: rep_seqs
    path "denoise_dada2/denoising_stats.qza",          emit: stats

    script:

    if (${val_read_type} == "single") {
        trunc_cmd = "--p-trunc-len ${val_trunc_len}"
    } else if (${val_read_type} == "paired") {
        trunc_cmd = "--p-trunc-len-f ${val_trunc_len} --p-trunc-len-r ${val_trunc_len}"
    } else {
        exit 1, "${val_read_type} must be single or paired!"
    }

    """
    echo 'Denoising with DADA2...'
    echo ${trunc_cmd}

    qiime dada2 denoise-${val_read_type} \
        --i-demultiplexed-seqs ${fastq_qza} \
        ${trunc_cmd} \
        --p-trunc-q ${val_trunc_q} \
        --p-n-threads 0 \
        --output-dir denoise_dada2 \
        --verbose
    """
}