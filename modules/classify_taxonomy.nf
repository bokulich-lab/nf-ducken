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