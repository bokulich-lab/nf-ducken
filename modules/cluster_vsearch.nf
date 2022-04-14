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

// process CLUSTER_CLOSED_OTU {
//
// }