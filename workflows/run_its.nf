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
          CUTADAPT_TRIM;
          CUTADAPT_TRIM_COMPLEMENT            } from '../modules/quality_control'
include { DENOISE_DADA2                       } from '../modules/denoise_dada2'
include { CLUSTER_CLOSED_OTU;
          COMBINE_FEATURE_TABLES;
          COMBINE_REP_SEQS;
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

workflow RUN_ITS {

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
    // Assign references and inputs for classification
    ch_otu_ref_qza        = Channel.fromPath ( "${params.otu_ref_file}",
                                              checkIfExists: true )
    ch_taxa_ref_qza       = Channel.fromPath ( "${params.taxonomy_ref_file}",
                                            checkIfExists: true )
    ch_trained_classifier = Channel.fromPath ( "${params.trained_classifier}",
                                               checkIfExists: true )

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

    // Pipeline start
    if (params.generate_input) {
        if (params.pipeline_type == "import") {
            inp_sample_file = params.fastq_manifest
        } else if (params.pipeline_type == "download") {
            inp_sample_file = params.inp_id_file
        } else {
            exit 1, "pipeline_type must be assigned correctly!"
        }
        // In lieu of ch_fastq_manifest or ch_inp_ids
        ch_inp_samples = Channel.fromPath ( "${inp_sample_file}",
                                            checkIfExists: true )
                                            .map { [0, it] }

        // Use local FASTQ files
        if (params.fastq_split.enabled) {
            SPLIT_FASTQ_MANIFEST ( ch_inp_samples )
            manifest_suffix = ~/${params.fastq_split.suffix}/
            ch_acc_ids = SPLIT_FASTQ_MANIFEST.out
                                .flatten()
                                .map { [(it.getName() - manifest_suffix), it] }
        } else {
            ch_acc_ids = ch_inp_samples
        }

        if (params.pipeline_type == "import") {
            IMPORT_FASTQ ( ch_acc_ids )
            ch_sra_artifact = IMPORT_FASTQ.out
        } else {
            // Download FASTQ files with q2-fondue
            GENERATE_ID_ARTIFACT ( ch_acc_ids )
            GET_SRA_DATA         ( GENERATE_ID_ARTIFACT.out )

            if (params.read_type == "single") {
                ch_sra_artifact = GET_SRA_DATA.out.single
            } else if (params.read_type == "paired") {
                ch_sra_artifact = GET_SRA_DATA.out.paired
            }
        }

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
    ch_to_fastqc = CHECK_FASTQ_TYPE.out.fqs.collect()
    RUN_FASTQC ( ch_to_fastqc )

    if (is_cutadapt_run) {
        ch_to_trim_1 = CHECK_FASTQ_TYPE.out.qza
        CUTADAPT_TRIM ( ch_to_trim_1 )
        ch_to_trim_2 = CUTADAPT_TRIM.out.qza
        ch_to_multiqc_1 = CUTADAPT_TRIM.out.stats
        CUTADAPT_TRIM_COMPLEMENT ( ch_to_trim_2 )
        ch_to_denoise = CUTADAPT_TRIM_COMPLEMENT.out.qza
        ch_to_multiqc_2 = CUTADAPT_TRIM_COMPLEMENT.out.stats
        ch_to_multiqc = ch_to_multiqc_1.combine( ch_to_multiqc_2 ).collect()
    } else {
        ch_to_denoise = CHECK_FASTQ_TYPE.out.qza
        ch_to_multiqc = "${projectDir}/assets/NO_FILE"
    }

    // Feature generation: Denoising for cleanup
    DENOISE_DADA2 ( ch_to_denoise )
    ch_denoised_tables = DENOISE_DADA2.out.table.collect()
    ch_denoised_seqs   = DENOISE_DADA2.out.seqs.collect()

    // Combine feature tables and representative sequences
    // from individually denoised samples (default option)
    COMBINE_FEATURE_TABLES ( ch_denoised_tables )
    COMBINE_REP_SEQS       ( ch_denoised_seqs   )
    ch_denoised_qzas = COMBINE_FEATURE_TABLES.out.join ( COMBINE_REP_SEQS.out )

    // Create MultiQC reports
    MULTIQC_STATS ( RUN_FASTQC.out, ch_to_multiqc )

    // Optional chimera filtering
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

    // Perform taxonomic classification
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