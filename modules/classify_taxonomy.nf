process CLASSIFY_TAXONOMY {
    input:
    path classifier
    path rep_seqs

    output:
    path "taxonomy.qza", emit: taxonomy_qza
    path "taxonomy.qzv", emit: taxonomy_qzv

    script:
    """
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
    input:
    path table
    path taxonomy
    val level

    output:
    path "collapsed_table.qza"

    script:
    """
    echo 'Collapsing frequencies for features to taxonomic level:' ${level}

    qiime taxa collapse \
        --i-table ${table} \
        --i-taxonomy ${taxonomy} \
        --p-level ${level} \
        --o-collapsed-table collapsed_table.qza
    """
}