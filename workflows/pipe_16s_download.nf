/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

// Import validation module
include { validateParams } from '../validate_inputs/paramsValidator'

// Check input path parameters to see if they exist

// Check mandatory parameters

/*
========================================================================================
    CONFIG FILES
========================================================================================
*/

/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/


include { GENERATE_ID_ARTIFACT; GET_SRA_DATA; } from '../modules/get_sra_data'
include { CHECK_FASTQ_TYPE; RUN_FASTQC;
          CUTADAPT_TRIM                       } from '../modules/quality_control'
include { DENOISE_DADA2                       } from '../modules/denoise_dada2'
include { CLUSTER_CLOSED_OTU;
          DOWNLOAD_REF_SEQS; FIND_CHIMERAS;
          FILTER_CHIMERAS                     } from '../modules/cluster_vsearch'
include { CLASSIFY_TAXONOMY; COLLAPSE_TAXA;
          DOWNLOAD_CLASSIFIER;
          DOWNLOAD_REF_TAXONOMY;
          COMBINE_TAXONOMIES;
          COMBINE_FEATURE_TABLES;
          COMBINE_FEATURE_TABLES as COMBINE_COLLAPSED_TABLES } from '../modules/classify_taxonomy'
include { MULTIQC_STATS                       } from '../modules/summarize_stats'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

workflow PIPE_16S_DOWNLOAD_INPUT {
    // Validate input parameters
    validateParams(params)

    // Log information
    log.info """\
         ${workflow.manifest.name} v${workflow.manifest.version}
         ==================================
         run name   : ${workflow.runName}
         run dir    : ${workflow.launchDir}
         session    : ${workflow.sessionId}
         --
         run as     : ${workflow.commandLine}
         run by     : ${workflow.userName}
         start time : ${workflow.start}
         configs    : ${workflow.configFiles}
         containers : ${workflow.containerEngine}:${workflow.container}
         profile    : ${workflow.profile}
         """
         .stripIndent()

    log.info """\
            TURDUCKEN - NF          ( params )
            ==================================
            read type                : ${params.read_type}
            input ids                : ${params.inp_id_file}
            fastq path               : ${params.fastq_manifest}
            classifier type          : ${params.classifier.method}
            input acquisition method : ${params.pipeline_type}
            --
            otu refs         : ${params.otu_ref_file}
            local classifier : ${params.trained_classifier}
            taxa ref file    : ${params.taxonomy_ref_file}
            qiime release    : ${params.qiime_release}
            --
            nextflow version : ${nextflow.version}
            nextflow build   : ${nextflow.build}
            """
            .stripIndent()

    // INPUT AND VARIABLES
    // Determine whether Cutadapt will be run
    if (params.primer_file) {
        Channel.fromPath ( "${params.primer_file}", checkIfExists: true )
            .splitCsv( sep: '\t', skip: 1 )
            .set { ch_primer_seqs }
    }

    if (params.inp_id_file) {       // TODO shift to input validation module
        ch_inp_ids        = Channel.fromPath ( "${params.inp_id_file}", checkIfExists: true )
    } else {
        exit 1, 'Input file with sample accession numbers does not exist or is not specified!'
    }
    if (!(params.email_address)) {
        exit 1, 'email_address parameter is required!'
    }
  
    if (!(params.read_type)) {
        exit 1, 'Read type parameter is required!'
    }
    
    // Determine whether reference downloads are necessary
    if (params.otu_ref_file) {
        flag_get_ref    = false
        ch_otu_ref_qza  = Channel.fromPath ( "${params.otu_ref_file}",
                                            checkIfExists: true )
    } else {
        flag_get_ref    = true
    }

    if (params.taxonomy_ref_file) {
        flag_get_ref_taxa = false
        ch_taxa_ref_qza   = Channel.fromPath ( "${params.taxonomy_ref_file}",
                                            checkIfExists: true )
    } else {
        flag_get_ref_taxa = true
    }

    if (params.trained_classifier) {
        flag_get_classifier        = false
        ch_trained_classifier      = Channel.fromPath ( "${params.trained_classifier}",
                                                        checkIfExists: true )
    } else {
        flag_get_classifier        = true
    }

    // Start of the  Pipeline
    // Download FASTQ files with q2-fondue
    GENERATE_ID_ARTIFACT ( ch_inp_ids )
    GET_SRA_DATA         ( GENERATE_ID_ARTIFACT.out )
    
    if (params.read_type == "single") {
        ch_sra_artifact = GET_SRA_DATA.out.single
    } else if (params.read_type == "paired") {
        ch_sra_artifact = GET_SRA_DATA.out.paired
    }
   
    // Quality control: FASTQ type check, trimming, QC
    // FASTQ check and QC
    CHECK_FASTQ_TYPE ( ch_sra_artifact )
    RUN_FASTQC ( CHECK_FASTQ_TYPE.out.fqs )

    if (params.primer_file) {
        ch_to_trim = CHECK_FASTQ_TYPE.out.qza
                        .combine ( ch_primer_seqs )
        CUTADAPT_TRIM ( ch_to_trim )
        ch_to_denoise = CUTADAPT_TRIM.out.qza
        ch_to_multiqc = CUTADAPT_TRIM.out.stats
    } else {
        ch_to_denoise = CHECK_FASTQ_TYPE.out.qza
                            .map { qza -> ["all", qza] }
        ch_to_multiqc = "${projectDir}/assets/NO_FILE"
    }
    
    // Feature generation: Denoising for cleanup
    DENOISE_DADA2 ( ch_to_denoise )
    ch_denoised_qzas = DENOISE_DADA2.out.table_seqs

    // Create multiqc reports
    MULTIQC_STATS ( RUN_FASTQC.out, ch_to_multiqc )

    // Feature generation: Clustering
    if (flag_get_ref) {
        DOWNLOAD_REF_SEQS ( flag_get_ref )
        ch_otu_ref_qza = DOWNLOAD_REF_SEQS.out
    }

    if (params.vsearch_chimera) {
        ch_denoised_qzas.tap { ch_to_find_chimeras }
        ch_to_find_chimeras.combine ( ch_otu_ref_qza )
            .set { ch_to_find_chimeras }

        FIND_CHIMERAS (
            ch_to_find_chimeras
            )

        ch_denoised_qzas
            .join ( FIND_CHIMERAS.out.nonchimeras )
            .set { ch_qzas_to_filter }

        FILTER_CHIMERAS (
            ch_qzas_to_filter
        )

        ch_qzas_to_cluster  = FILTER_CHIMERAS.out.filt_qzas

    } else {
        ch_denoised_qzas.set { ch_qzas_to_cluster }
    }

    ch_qzas_to_cluster.combine ( ch_otu_ref_qza )
        .set { ch_qzas_to_cluster }

    CLUSTER_CLOSED_OTU (
        ch_qzas_to_cluster
        )

    // Classification
    if (flag_get_classifier) {
        DOWNLOAD_CLASSIFIER ( flag_get_classifier )
        ch_trained_classifier = DOWNLOAD_CLASSIFIER.out
    }

    if (flag_get_ref_taxa) {
        DOWNLOAD_REF_TAXONOMY ( flag_get_ref_taxa )
        ch_taxa_ref_qza = DOWNLOAD_REF_TAXONOMY.out
    }

    ch_to_classify = CLUSTER_CLOSED_OTU.out.seqs
                        .combine ( ch_trained_classifier )
                        .combine ( ch_otu_ref_qza )
                        .combine ( ch_taxa_ref_qza )

    CLASSIFY_TAXONOMY ( ch_to_classify )

    // Merge feature tables
    CLUSTER_CLOSED_OTU.out.table.tap { ch_tables_to_combine }
    ch_tables_to_combine = ch_tables_to_combine
                            .map { it[1] }
                            .collect()
    //COMBINE_FEATURE_TABLES ( "feature", ch_tables_to_combine )

    // Split taxonomies off to merge
    CLASSIFY_TAXONOMY.out.taxonomy_qza.tap { ch_taxa_to_combine }
    ch_taxa_to_combine = ch_taxa_to_combine
                            .map { it[1] }
                            .collect()
    //COMBINE_TAXONOMIES ( ch_taxa_to_combine )

    // Collapse taxa and merge
    CLUSTER_CLOSED_OTU.out.table
        .join ( CLASSIFY_TAXONOMY.out.taxonomy_qza )
        .set { ch_table_to_collapse }

    COLLAPSE_TAXA ( ch_table_to_collapse )

    ch_collapsed_tables_to_combine = COLLAPSE_TAXA.out.collect()
    //COMBINE_COLLAPSED_TABLES ( "collapsed", ch_collapsed_tables_to_combine )

}

/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/

// TODO implement functions
workflow.onComplete {
    print("Success!")
}