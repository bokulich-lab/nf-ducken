process CLUSTER_CLOSED_OTU {
    label "container_qiime2"
    label "process_local"
    tag "${sample_id}"

    beforeScript "export NXF_TEMP=$PWD/tmp_cluster"
    beforeScript "mkdir $NXF_TEMP; export TMPDIR=$PWD/tmp_cluster"
    afterScript "rm -rf $PWD/tmp_cluster"

    input:
    tuple val(sample_id), path(table), path(rep_seqs), path(ref_otus)

    output:
    tuple val(sample_id), path("${sample_id}_clustered_table.qza"),     emit: table
    tuple val(sample_id), path("${sample_id}_clustered_sequences.qza"), emit: seqs
    path "${sample_id}_unmatched_sequences.qza",                        emit: unmatched_seqs

    script:
    """
    echo 'Clustering features with VSEARCH...'

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
    output:
    path "ref_seqs.qza"

    when:
    flag_get_ref

    script:
    """
    echo 'Downloading default OTU reference artifact...'

    wget -O ref_seqs.qza ${params.otu_ref_url}
    """
}

process FIND_CHIMERAS {
    label "container_qiime2"
    label "process_local"
    tag "${sample_id}"
    publishDir "${params.outdir}/stats/", pattern: "*_stats.qza"

    input:
    tuple val(sample_id), path(table), path(rep_seqs), path(ref_otus)

    output:
    tuple val(sample_id), path("${sample_id}_nonchimeras.qza"), emit: nonchimeras
    path "${sample_id}_chimeras.qza",                           emit: chimeras
    path "${sample_id}_stats.qza",                              emit: stats

    when:
    params.vsearch_chimera

    script:
    """
    echo 'Using reference sequences to search for chimeras...'

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
        --o-stats ${sample_id}_stats.qza \
        --verbose
    """
}

process FILTER_CHIMERAS {
    label "container_qiime2"
    tag "${sample_id}"
    publishDir "${params.outdir}/stats/", pattern: "*.qzv"

    input:
    tuple val(sample_id), path(table), path(rep_seqs), path(nonchimera_qza)

    output:
    tuple val(sample_id), path("${sample_id}_table_filt_chimera.qza"), path("${sample_id}_seqs_filt_chimera.qza"), emit: filt_qzas
    path "${sample_id}_table_filt_chimera.qzv", emit: viz_table

    when:
    params.vsearch_chimera

    script:
    """
    echo 'Filtering chimeras from feature table and sequences...'

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
        --o-visualization ${sample_id}_table_filt_chimera.qzv
    """
}