process DEREPLICATE_SEQS {
    input:
    path seq_qza

    output:
    path "output_table.qza",    emit: table
    path "output_req_seqs.qza", emit: rep_seqs

    script:
    """
    echo 'Dereplicating sequences with VSEARCH...'

    qiime vsearch dereplicate-sequences \
        --i-sequences ${seq_qza} \
        --o-dereplicated-table output_table.qza \
        --o-dereplicated-sequences output_rep_seqs.qza
    """
}

process CLUSTER_CLOSED_OTU {
    input:
    path table
    path rep_seqs
    path ref_otus

    output:

    script:
    """
    echo 'Clustering features with VSEARCH...'

    qiime vsearch cluster-features-closed-reference \
        --i-table ${table} \
        --i-sequences ${rep_seqs} \
        --i-reference-sequences ${ref_otus} \
        --p-perc-identity 1.00 \
        --output-dir vsearch_otus
    """
}