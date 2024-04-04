process CLASSIFY_TAXONOMY {
    label "container_qiime2"
    label "process_high"
    label "error_retry"
    tag "${sample_id}"

    publishDir "${params.outdir}/", pattern: "*_taxonomy.qza"
    publishDir "${params.outdir}/", pattern: "${rep_seqs}"

    input:
    tuple val(sample_id), path(rep_seqs), path(classifier), path(ref_seqs), path(ref_taxonomy)

    output:
    tuple val(sample_id), path("${sample_id}_taxonomy.qza"), emit: taxonomy_qza
    path "${sample_id}_taxonomy.qzv",                        emit: taxonomy_qzv
    path "${rep_seqs}",                                      emit: rep_seqs

    script:
    if (params.classifier.method == "sklearn") {
        """
        echo 'Generating taxonomic assignments with the sklearn fitted feature classifier...'

        export NXF_TEMP=\${PWD}/tmp_taxa
        export JOBLIB_TEMP_FOLDER=\${PWD}/tmp_taxa
        mkdir \${PWD}/tmp_taxa
        export TMPDIR=\${PWD}/tmp_taxa

        qiime feature-classifier classify-sklearn \
            --i-classifier ${classifier} \
            --i-reads ${rep_seqs} \
            --p-reads-per-batch ${params.classifier.reads_per_batch} \
            --p-n-jobs ${params.classifier.num_jobs} \
            --p-pre-dispatch ${params.classifier.pre_dispatch} \
            --p-confidence ${params.classifier.confidence} \
            --p-read-orientation ${params.classifier.read_orientation} \
            --o-classification ${sample_id}_taxonomy.qza

        echo 'Feature classification complete.'

        qiime metadata tabulate \
            --m-input-file ${sample_id}_taxonomy.qza \
            --o-visualization ${sample_id}_taxonomy.qzv

        echo 'Taxonomy generated as QIIME 2 visualization.'
        """
    } else if (params.classifier.method == "blast") {
        """
        echo 'Generating taxonomic assignments with a BLAST+ based feature classifier...'

        export NXF_TEMP=\${PWD}/tmp_taxa
        export JOBLIB_TEMP_FOLDER=\${PWD}/tmp_taxa
        mkdir \${PWD}/tmp_taxa
        export TMPDIR=\${PWD}/tmp_taxa

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

        export NXF_TEMP=\${PWD}/tmp_taxa
        export JOBLIB_TEMP_FOLDER=\${PWD}/tmp_taxa
        mkdir \${PWD}/tmp_taxa
        export TMPDIR=\${PWD}/tmp_taxa

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
    path "${sample_id}_collapsed_${params.taxa_level}_table.qza"
    path "${table}"

    script:
    """
    echo 'Collapsing frequencies for features to taxonomic level:' ${params.taxa_level}

    qiime taxa collapse \
        --i-table ${table} \
        --i-taxonomy ${taxonomy} \
        --p-level ${params.taxa_level} \
        --o-collapsed-table ${sample_id}_collapsed_${params.taxa_level}_table.qza \
        --verbose
    """
}

process CREATE_BARPLOT {
    label "container_qiime2"
    tag "${sample_id}"
    publishDir "${params.outdir}/"

    input:
    tuple val(sample_id), path(table), path(taxonomy)

    output:
    path "${sample_id}_taxa_barplot.qzv"

    script:
    """
    echo 'Generating a taxonomic barplot...'

    qiime taxa barplot \
        --i-table ${table} \
        --i-taxonomy ${taxonomy} \
        --o-visualization ${sample_id}_taxa_barplot.qzv \
        --verbose
    """
}

process COMBINE_TAXONOMIES {
    label "container_qiime2"
    publishDir "${params.outdir}/"

    input:
    path(taxonomy_list)

    output:
    path "merged_taxonomy.qza"
    path "merged_taxonomy.qzv"

    script:
    """
    echo 'Combining taxonomies into a single output...'

    full_taxonomy_list=""
    for taxonomy in ${taxonomy_list}; do
      full_taxonomy_list=\"\${full_taxonomy_list} \${taxonomy}\"
    done

    qiime feature-table merge-taxa \
        --i-data \${full_taxonomy_list} \
        --o-merged-data merged_taxonomy.qza \
        --verbose

    qiime metadata tabulate \
        --m-input-file merged_taxonomy.qza \
        --o-visualization merged_taxonomy.qzv
    """
}

process COMBINE_FEATURE_TABLES {
    label "container_qiime2"
    publishDir "${params.outdir}/"

    input:
    val(inp_type)
    path(table_list)

    output:
    path "merged_${inp_type}_table.qza"

    script:
    """
    echo 'Combining ${inp_type} feature tables into a single output...'

    full_table_list=""
    for table in ${table_list}; do
      full_table_list=\"\${full_table_list} \${table}\"
    done

    qiime feature-table merge \
        --i-tables \${full_table_list} \
        --o-merged-table merged_${inp_type}_table.qza \
        --verbose
    """
}

process DOWNLOAD_CLASSIFIER {
    input:
    val(flag)

    output:
    path "classifier.qza"

    script:
    """
    echo 'Downloading default taxonomy feature classifier...'

    wget -O classifier.qza ${params.trained_classifier_url}
    """
}

process DOWNLOAD_REF_TAXONOMY {
    input:
    val(flag)

    output:
    path "ref_taxonomy.qza"

    script:
    """
    echo 'Downloading default reference taxonomy...'

    wget -O ref_taxonomy.qza ${params.taxonomy_ref_url}
    """
}