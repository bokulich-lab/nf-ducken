process CLUSTER_CLOSED_OTU {
    label "container_qiime2"
    label "process_local"
    label "error_retry"
    publishDir "${params.outdir}/", pattern: "*_clustered_table.qza"

    afterScript "rm -rf \${PWD}/tmp_cluster"

    input:
    tuple val(sample_id), path(table), path(rep_seqs), path(ref_otus)

    output:
    tuple val(sample_id), path("${sample_id}_clustered_table.qza"),     emit: table
    tuple val(sample_id), path("${sample_id}_clustered_sequences.qza"), emit: seqs
    path "${sample_id}_unmatched_sequences.qza",                        emit: unmatched_seqs

    script:
    """
    echo 'Clustering features with VSEARCH...'

    export NXF_TEMP=\${PWD}/tmp_cluster
    mkdir \${PWD}/tmp_cluster

    qiime vsearch cluster-features-closed-reference \
        --i-table ${table} \
        --i-sequences ${rep_seqs} \
        --i-reference-sequences ${ref_otus} \
        --p-perc-identity ${params.vsearch.perc_identity} \
        --p-strand ${params.vsearch.strand} \
        --p-threads ${params.vsearch.num_threads} \
        --o-clustered-table ${sample_id}_clustered_table.qza \
        --o-clustered-sequences ${sample_id}_clustered_sequences.qza \
        --o-unmatched-sequences ${sample_id}_unmatched_sequences.qza \
        --verbose
    """
}

process DOWNLOAD_REF_SEQS {
    input:
    val(flag)

    output:
    path "ref_seqs.qza"

    script:
    """
    echo 'Downloading default OTU reference artifact...'

    wget -O ref_seqs.qza ${params.otu_ref_url}
    """
}

process FIND_CHIMERAS {
    label "container_qiime2"
    label "process_local"
    publishDir "${params.outdir}/stats/chimera_check/", pattern: "*_chimera_checking_summary.qza"

    afterScript "rm -rf \${PWD}/tmp_chimera"

    input:
    tuple val(sample_id), path(table), path(rep_seqs), path(ref_otus)

    output:
    tuple val(sample_id), path("${sample_id}_nonchimeras.qza"), emit: nonchimeras
    path "${sample_id}_chimeras.qza",                           emit: chimeras
    path "${sample_id}_chimera_checking_summary.qza",                              emit: stats

    when:
    params.vsearch_chimera

    script:
    """
    echo 'Using reference sequences to search for chimeras...'

    export NXF_TEMP=\${PWD}/tmp_chimera
    mkdir \${PWD}/tmp_chimera

    qiime vsearch uchime-ref \
        --i-sequences ${rep_seqs} \
        --i-table ${table} \
        --i-reference-sequences ${ref_otus} \
        --p-dn ${params.uchime_ref.dn} \
        --p-mindiffs ${params.uchime_ref.min_diffs} \
        --p-mindiv ${params.uchime_ref.min_div} \
        --p-minh ${params.uchime_ref.min_h} \
        --p-xn ${params.uchime_ref.xn} \
        --p-threads ${params.uchime_ref.num_threads} \
        --o-chimeras ${sample_id}_chimeras.qza \
        --o-nonchimeras ${sample_id}_nonchimeras.qza \
        --o-stats ${sample_id}_chimera_checking_summary.qza \
        --verbose
    """
}

process FILTER_CHIMERAS {
    label "container_qiime2"
    publishDir "${params.outdir}/stats/chimera_check/", pattern: "*.qzv"

    afterScript "rm -rf \${PWD}/tmp_filt"

    input:
    tuple val(sample_id), path(table), path(rep_seqs), path(nonchimera_qza)

    output:
    tuple val(sample_id), path("${sample_id}_table_filt_chimera.qza"), path("${sample_id}_seqs_filt_chimera.qza"), emit: filt_qzas
    path "${sample_id}_chimera_free_table.qzv", emit: viz_table

    when:
    params.vsearch_chimera

    script:
    """
    echo 'Filtering chimeras from feature table and sequences...'

    export NXF_TEMP=\${PWD}/tmp_filt
    mkdir \${PWD}/tmp_filt

    qiime feature-table filter-features \
        --i-table ${table} \
        --m-metadata-file ${nonchimera_qza} \
        --o-filtered-table ${sample_id}_table_filt_chimera.qza

    qiime feature-table filter-seqs \
        --i-data ${rep_seqs} \
        --m-metadata-file ${nonchimera_qza} \
        --o-filtered-data ${sample_id}_seqs_filt_chimera.qza

    qiime feature-table summarize \
        --i-table ${sample_id}_table_filt_chimera.qza \
        --o-visualization ${sample_id}_chimera_free_table.qzv
    """
}

process SUMMARIZE_FEATURE_TABLE {
    label "container_qiime2"
    publishDir "${params.outdir}"

    input:
    tuple val(sample_id), path(table)

    output:
    path "${sample_id}_feature_table.qzv"

    script:
    """
    echo 'Generating a visual and tabular summary of the final feature table...'

    qiime feature-table summarize \
        --i-table ${table} \
        --o-visualization ${sample_id}_feature_table.qzv
    """
}

process COMBINE_FEATURE_TABLES {
    label "container_qiime2"
    publishDir "${params.outdir}/"

    input:
    path(table_list)

    output:
    tuple val("merged"), path("merged_table.qza")

    script:
    """
    echo 'Combining denoised feature tables into a single output...'

    full_table_list=""
    for table in ${table_list}; do
      full_table_list=\"\${full_table_list} \${table}\"
    done

    qiime feature-table merge \
        --i-tables \${full_table_list} \
        --o-merged-table merged_table.qza \
        --verbose
    """
}

process COMBINE_REP_SEQS {
    label "container_qiime2"
    publishDir "${params.outdir}/"

    input:
    path(seq_list)

    output:
    tuple val("merged"), path("merged_seqs.qza")

    script:
    """
    echo 'Combining denoised representative sequences into a single output...'

    full_seq_list=""
    for seq in ${seq_list}; do
      full_seq_list=\"\${full_seq_list} \${seq}\"
    done

    qiime feature-table merge-seqs \
        --i-data \${full_seq_list} \
        --o-merged-data merged_seqs.qza \
        --verbose
    """
}