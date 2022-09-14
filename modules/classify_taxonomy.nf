process CLASSIFY_TAXONOMY {
    label "container_qiime2"
    label "process_local"
    label "error_retry"
    tag "${sample_id}"
    publishDir "${params.outdir}/", pattern: "*.qzv"

    beforeScript "cp ${classifier} classifier.qza; cp ${rep_seqs} rep_seqs.qza"
    beforeScript "export NXF_TEMP=$PWD/tmp_taxa"
    beforeScript "mkdir $NXF_TEMP; export TMPDIR=$PWD/tmp_taxa"
    afterScript "rm -rf $PWD/tmp_taxa"

    input:
    tuple val(sample_id), path(rep_seqs), path(classifier), path(ref_seqs), path(ref_taxonomy)

    output:
    tuple val(sample_id), path("${sample_id}_taxonomy.qza"), emit: taxonomy_qza
    path "${sample_id}_taxonomy.qzv", emit: taxonomy_qzv

    script:
    if (params.classifier.method == "sklearn") {
        """
        echo 'Generating taxonomic assignments with the sklearn fitted feature classifier...'

        qiime feature-classifier classify-sklearn \
            --i-classifier ${classifier} \
            --i-reads ${rep_seqs} \
            --p-reads-per-batch ${params.classifier.reads_per_batch} \
            --p-n-jobs ${params.classifier.num_jobs} \
            --p-pre-dispatch ${params.classifier.pre_dispatch} \
            --p-confidence ${params.classifier.confidence} \
            --p-read-orientation ${params.classifier.read_orientation} \
            --o-classification ${sample_id}_taxonomy.qza \
            --verbose

        qiime metadata tabulate \
            --m-input-file ${sample_id}_taxonomy.qza \
            --o-visualization ${sample_id}_taxonomy.qzv
        """
    } else if (params.classifier.method == "blast") {
        """
        cp ${ref_seqs} ref_seqs.qza
        cp ${ref_taxonomy} ref_taxonomy.qza

        echo 'Generating taxonomic assignments with a BLAST+ based feature classifier...'

        qiime feature-classifier classify-consensus-blast \
            --i-query ${rep_seqs} \
            --i-reference-reads ${ref_seqs} \
            --i-reference-taxonomy ${ref_taxonomy} \
            --p-maxaccepts ${params.classifier.max_accepts} \
            --p-perc-identity ${params.classifier.perc_identity} \
            --p-query-cov ${params.classifier.perc_identity} \
            --p-strand ${params.classifier.strand} \
            --p-evalue ${params.classifier.evalue} \
            --p-min-consensus ${params.classifier.min_consensus} \
            --p-unassignable-label ${params.classifier.unassignable_label} \
            --o-classification ${sample_id}_taxonomy.qza \
            --verbose

        qiime metadata tabulate \
            --m-input-file ${sample_id}_taxonomy.qza \
            --o-visualization ${sample_id}_taxonomy.qzv
        """
    } else if (params.classifier.method == "vsearch") {
        """
        echo 'Generating taxonomic assignments with the VSEARCH fitted feature classifier...'

        qiime feature-classifier classify-consensus-vsearch \
            --i-query ${rep_seqs} \
            --i-reference-reads ${ref_seqs} \
            --i-reference-taxonomy ${ref_taxonomy} \
            --p-maxaccepts ${params.classifier.max_accepts} \
            --p-perc-identity ${params.classifier.perc_identity} \
            --p-query-cov ${params.classifier.perc_identity} \
            --p-strand ${params.classifier.strand} \
            --p-min-consensus ${params.classifier.min_consensus} \
            --p-unassignable-label ${params.classifier.unassignable_label} \
            --p-search-exact ${params.classifier.search_exact} \
            --p-top-hits-only ${params.classifier.top_hits_only} \
            --p-maxhits ${params.classifier.max_hits} \
            --p-maxrejects ${params.classifier.max_rejects} \
            --p-output-no-hits ${params.classifier.output_no_hits} \
            --p-weak-id ${params.classifier.weak_id} \
            --p-threads ${params.classifier.num_threads} \
            --o-classification ${sample_id}_taxonomy.qza \
            --verbose

        qiime metadata tabulate \
            --m-input-file ${sample_id}_taxonomy.qza \
            --o-visualization ${sample_id}_taxonomy.qzv
        """
    }
}

process COLLAPSE_TAXA {
    label "container_qiime2"
    tag "${sample_id}"
    publishDir "${params.outdir}/"

    input:
    tuple val(sample_id), path(table), path(taxonomy)

    output:
    path "${sample_id}_collapsed_table.qza"

    script:
    """
    echo 'Collapsing frequencies for features to taxonomic level:' ${params.taxa_level}

    qiime taxa collapse \
        --i-table ${table} \
        --i-taxonomy ${taxonomy} \
        --p-level ${params.taxa_level} \
        --o-collapsed-table ${sample_id}_collapsed_table.qza
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

process DOWNLOAD_REF_TAXONOMY {
    output:
    path "ref_taxonomy.qza"

    when:
    flag_get_ref_taxa

    script:
    """
    echo 'Download default reference taxonomy...'

    wget -O ref_taxonomy.qza ${params.taxonomy_ref_url}
    """
}
