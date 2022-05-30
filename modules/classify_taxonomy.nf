process CLASSIFY_TAXONOMY {
    label "singularity_qiime2"
    label "process_medium"
    scratch true

    input:
    path classifier
    path rep_seqs

    output:
    path "taxonomy.qza", emit: taxonomy_qza
    path "taxonomy.qzv", emit: taxonomy_qzv

    script:
    """
    # Hard copy required for q2-feature-classifier
    cp ${classifier} classifier.qza
    cp ${rep_seqs} rep_seqs.qza

    echo 'Generating taxonomic assignments with a feature classifier...'

    qiime feature-classifier classify-sklearn \
        --i-classifier ${classifier} \
        --i-reads ${rep_seqs} \
        --p-n-jobs -1 \
        --o-classification taxonomy.qza \
        --verbose

    qiime metadata tabulate \
        --m-input-file taxonomy.qza \
        --o-visualization taxonomy.qzv
    """
}

process COLLAPSE_TAXA {
    label "singularity_qiime2"
    publishDir "${parmas.outdir}/taxa/"

    input:
    path table
    path taxonomy

    output:
    path "collapsed_table.qza"

    script:
    """
    echo 'Collapsing frequencies for features to taxonomic level:' ${params.taxa_level}

    qiime taxa collapse \
        --i-table ${table} \
        --i-taxonomy ${taxonomy} \
        --p-level ${params.taxa_level} \
        --o-collapsed-table collapsed_table.qza
    """
}

process DOWNLOAD_CLASSIFIER {
    output:
    path "classifier.qza"

    when:
    flag_get_classifier

    script:
    """
    echo 'Downloading default taxonomy feature classifier...'

    wget -O classifier.qza ${params.classifier_url}
    """
}