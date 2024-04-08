/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

// Import validation module
include { validateParams } from '../lib/paramsValidator'

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

include { IMPORT_FASTQ; SPLIT_FASTQ_MANIFEST  } from '../modules/get_sra_data'
include { CHECK_FASTQ_TYPE; RUN_FASTQC;
          CUTADAPT_TRIM                       } from '../modules/quality_control'
include { DENOISE_DADA2                       } from '../modules/denoise_dada2'
include { CLUSTER_CLOSED_OTU;
          DOWNLOAD_REF_SEQS; FIND_CHIMERAS;
          FILTER_CHIMERAS;
          SUMMARIZE_FEATURE_TABLE             } from '../modules/cluster_vsearch'
include { CLASSIFY_TAXONOMY; COLLAPSE_TAXA;
          CREATE_BARPLOT; TABULATE_SEQS;
          DOWNLOAD_CLASSIFIER;
          DOWNLOAD_REF_TAXONOMY               } from '../modules/classify_taxonomy'
include { MULTIQC_STATS                       } from '../modules/summarize_stats'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

workflow PIPE_16S_IMPORT_INPUT {

    // Validate input parameters
    if (params.validate_parameters) {
        try {
            validateParams(params)
        } catch (AssertionError e) {
            println "Parameter validation failed: ${e.message}"
            System.exit(1)
        }
    }

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
            DUCKEN - NF          ( params )
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
    if (params.cutadapt.front) {
        is_cutadapt_run = true
    } else if (params.cutadapt.front_f) {
        if (params.cutadapt.front_r) {
            is_cutadapt_run = true
        } else {
            is_cutadapt_run = null
        }
    } else {
        is_cutadapt_run = null
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
    
    // Pipeline start
    if (params.generate_input) {
        ch_fastq_manifest = Channel.fromPath ( "${params.fastq_manifest}",
                                        checkIfExists: true )
                                        .map { [0, it] }
                                        
        // Use local FASTQ files
        if (params.fastq_split.enabled == "True") {
            SPLIT_FASTQ_MANIFEST ( ch_fastq_manifest )
            manifest_suffix = ~/${params.fastq_split.suffix}/
            ch_acc_ids = SPLIT_FASTQ_MANIFEST.out
                                .flatten()
                                .map { [(it.getName() - manifest_suffix), it] }
        } else {
            ch_acc_ids = ch_fastq_manifest
        }

        IMPORT_FASTQ ( ch_acc_ids )
        ch_sra_artifact = IMPORT_FASTQ.out
    
    } else {
        if (!params.input_artifact) {
            println("Error: 'input_artifact' parameter is not set.")
            System.exit(1)
        } else {
            Channel
                .fromPath(params.input_artifact, checkIfExists: true)
                .map { [ 0, it ] }
                .set { ch_sra_artifact }
        }
    }

    // Quality control: FASTQ type check, trimming, QC
    // FASTQ check and QC
    CHECK_FASTQ_TYPE ( ch_sra_artifact )
    RUN_FASTQC ( CHECK_FASTQ_TYPE.out.fqs )
    
    if (is_cutadapt_run) {
        ch_to_trim = CHECK_FASTQ_TYPE.out.qza
        CUTADAPT_TRIM ( ch_to_trim )
        ch_to_denoise = CUTADAPT_TRIM.out.qza
        ch_to_multiqc = CUTADAPT_TRIM.out.stats.collect()
    } else {
        ch_to_denoise = CHECK_FASTQ_TYPE.out.qza
        ch_to_multiqc = "${projectDir}/assets/NO_FILE"
    }

    // Feature generation: Denoising for cleanup
    DENOISE_DADA2 ( ch_to_denoise )
    ch_denoised_qzas = DENOISE_DADA2.out.table_seqs

    // Create MultiQC reports
    MULTIQC_STATS ( RUN_FASTQC.out, ch_to_multiqc )

    // Optional chimera filtering
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

        ch_denoised_qzas.tap { ch_denoised_qzas_to_filter }
        ch_denoised_qzas_to_filter.join ( FIND_CHIMERAS.out.nonchimeras )
            .set { ch_qzas_to_filter }

        FILTER_CHIMERAS (
            ch_qzas_to_filter
        )

        FILTER_CHIMERAS.out.filt_qzas.tap { ch_qzas_to_cluster }

    } else {
        ch_denoised_qzas.tap { ch_qzas_to_cluster }
    }

    // Optional closed-reference OTU clustering
    ch_qzas_to_cluster.combine ( ch_otu_ref_qza )
        .set { ch_qzas_to_cluster }

    if (params.closed_ref_cluster) {
        CLUSTER_CLOSED_OTU (
            ch_qzas_to_cluster
        )
        ch_seqs_to_classify = CLUSTER_CLOSED_OTU.out.seqs
    } else {
        ch_seqs_to_classify = ch_qzas_to_cluster
                                .map { it -> [it[0], it[2]] }
                                // Just sample ID and sequences
    }

    // Classification
    if (flag_get_classifier) {
        DOWNLOAD_CLASSIFIER ( flag_get_classifier )
        ch_trained_classifier = DOWNLOAD_CLASSIFIER.out
    }

    if (flag_get_ref_taxa) {
        DOWNLOAD_REF_TAXONOMY ( flag_get_ref_taxa )
        ch_taxa_ref_qza = DOWNLOAD_REF_TAXONOMY.out
    }

    ch_to_classify = ch_seqs_to_classify
                        .combine ( ch_trained_classifier )
                        .combine ( ch_otu_ref_qza )
                        .combine ( ch_taxa_ref_qza )

    CLASSIFY_TAXONOMY ( ch_to_classify )
    CLASSIFY_TAXONOMY.out.taxonomy_qza
        .tap { ch_taxa_to_tabulate }
        .set { ch_taxa_to_viz }

    ch_taxa_to_tabulate
        .join ( CLASSIFY_TAXONOMY.out.rep_seqs )
        .set { ch_to_tabulate_seqs }

    TABULATE_SEQS ( ch_to_tabulate_seqs )

    // Determine final feature tables/seqs
    if (params.closed_ref_cluster) {
        CLUSTER_CLOSED_OTU.out.table.tap { ch_tables_to_collapse }
    } else if (params.vsearch_chimera) {
        FILTER_CHIMERAS.out.filt_qzas.tap { ch_tables_to_collapse }
    } else {
        ch_denoised_qzas.tap { ch_denoised_for_collapse }
        ch_denoised_for_collapse.map { it -> [it[0], it[1]] }
                             .set { ch_tables_to_collapse }
    }

    // Collapse taxa and merge
    ch_tables_to_collapse
        .tap  { ch_table_to_summarize }
        .join ( ch_taxa_to_viz        )
        .tap  { ch_to_create_barplot  }
        .set  { ch_to_collapse_taxa   }

    SUMMARIZE_FEATURE_TABLE ( ch_table_to_summarize )
    CREATE_BARPLOT ( ch_to_create_barplot )
    COLLAPSE_TAXA  ( ch_to_collapse_taxa  )

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