process CLUSTER_CLOSED_OTU {
    label "singularity_qiime2"
    label "process_local"
    scratch true

    input:
    path table
    path rep_seqs
    path ref_otus

    output:
    path "vsearch_otus/clustered_table.qza",     emit: table
    path "vsearch_otus/clustered_sequences.qza", emit: seqs
    path "vsearch_otus/unmatched_sequences.qza", emit: unmatched_seqs

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
        --output-dir vsearch_otus \
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
    input:
    path table
    path rep_seqs
    path ref_otus

    output:
    path "chimera/chimeras.qza",    emit: chimeras
    path "chimera/nonchimeras.qza", emit: nonchimeras
    path "chimera/stats.qza",       emit: stats

    when:
    params.vsearch_chimera

    script:
    """
    echo 'Using reference sequences to search for chimeras...'

    qiime vsearch uchime-ref \
        --i-sequences ${rep_seqs} \
        --i-table ${table} \
        --i-reference-sequences ${ref_otus} \
        --p-dn ${uchime_ref.dn} \
        --p-mindiffs ${uchime_ref.min_diffs} \
        --p-mindiv ${uchime_ref.min_div} \
        --p-minh ${uchime_ref.min_h} \
        --p-xn ${uchime_ref.xn} \
        --p-threads ${uchime_ref.num_threads} \
        --verbose
    """
}