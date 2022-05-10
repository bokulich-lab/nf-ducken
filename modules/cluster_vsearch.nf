process CLUSTER_CLOSED_OTU {
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
        --p-perc-identity 1.00 \
        --output-dir vsearch_otus \
        --verbose
    """
}

process DOWNLOAD_REF_SEQS {
    input:
    val otu_ref_url

    output:
    path "ref_seqs.qza"

    when:
    flag_get_ref = true

    script:
    """
    echo 'Downloading default OTU reference artifact...'

    wget -O ref_seqs.qza ${otu_ref_url}
    """
}