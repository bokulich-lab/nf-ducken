process DEREPLICATE {
    input:
    path seq_qza

    output:
    path output-table.qza,    emit: table
    path output-req-seqs.qza, emit: rep_seqs

    script:
    """
    echo 'Dereplicating sequences with VSEARCH...'

    qiime vsearch dereplicate-sequences \
        --i-sequences ${seq_qza} \
        --o-dereplicated-table output-table.qza \
        --o-dereplicated-sequences output-rep-seqs.qza
    """
}

process CLUSTER_CLOSED_OTU {

}