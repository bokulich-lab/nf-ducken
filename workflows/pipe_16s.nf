/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

// Validate input parameters

// Check input path parameters to see if they exist

// Check mandatory parameters

/*
========================================================================================
    CONFIG FILES
========================================================================================
*/

/*
========================================================================================
    INPUT AND VARIABLES
========================================================================================
*/

// Intermediate process skipping
// Executed in reverse chronology
if (params.denoised_table && params.denoised_seqs) {
    ch_denoised_table = Channel.fromPath ( "${params.denoised_table}", checkIfExists: true )
    ch_denoised_seqs  = Channel.fromPath ( "${params.denoised_seqs}",  checkIfExists: true )
    ch_denoised_table.concat(ch_denoised_seqs)
        .map { ["all", it[0], it[1]] }
        .set { ch_denoised_qzas }
    start_process  = "clustering"

} else if (params.fastq_manifest) {
    ch_fastq_manifest = Channel.fromPath ( "${params.fastq_manifest}",
                                           checkIfExists: true )
    start_process = "fastq_import"

    if (!(params.phred_offset == 64 || params.phred_offset == 33)) {
        exit 1, 'The only valid PHRED offset values are 33 or 64!'
    }

} else {
    start_process = "id_import"
}

// Required user inputs
switch (start_process) {
    case "id_import":
        if (params.inp_id_file) {       // TODO shift to input validation module
            ch_inp_ids        = Channel.fromPath ( "${params.inp_id_file}", checkIfExists: true )
            ch_fastq_manifest = Channel.empty()
        } else {
            exit 1, 'Input file with sample accession numbers does not exist or is not specified!'
        }
        break

    case "fastq_import":
        ch_inp_ids = Channel.empty()
        println "Skipping FASTQ download..."
        break

    case "clustering":
        ch_inp_ids        = Channel.empty()
        ch_fastq_manifest = Channel.empty()
        println "Skipping DADA2..."
        break
}

// Navigate user-input parameters necessary for pre-clustering steps
if (start_process != "clustering") {
    if (!(params.read_type)) {
        exit 1, 'Read type parameter is required!'
    }
}

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

/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

include { GENERATE_ID_ARTIFACT; GET_SRA_DATA;
          CHECK_FASTQ_TYPE; IMPORT_FASTQ;
          SPLIT_FASTQ_MANIFEST                } from '../modules/get_sra_data'
include { DENOISE_DADA2                       } from '../modules/denoise_dada2'
include { CLUSTER_CLOSED_OTU;
          DOWNLOAD_REF_SEQS; FIND_CHIMERAS;
          FILTER_CHIMERAS                     } from '../modules/cluster_vsearch'
include { CLASSIFY_TAXONOMY; COLLAPSE_TAXA;
          DOWNLOAD_CLASSIFIER;
          DOWNLOAD_REF_TAXONOMY               } from '../modules/classify_taxonomy'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

workflow PIPE_16S {
    // Download
    GENERATE_ID_ARTIFACT ( ch_inp_ids )
    GET_SRA_DATA         ( GENERATE_ID_ARTIFACT.out )

    if (params.read_type == "single") {
        ch_sra_artifact = GET_SRA_DATA.out.single
    } else if (params.read_type == "paired") {
        ch_sra_artifact = GET_SRA_DATA.out.paired
    }

    if (params.fastq_split.enabled) {
        SPLIT_FASTQ_MANIFEST ( ch_fastq_manifest )

        manifest_suffix = ~/${params.fastq_split.suffix}/
        ch_split_manifests = SPLIT_FASTQ_MANIFEST.out
            .flatten()
            .map { [(it.getName() - manifest_suffix), it] }

        IMPORT_FASTQ ( ch_split_manifests )

    } else {
        ch_fastq_manifest = ch_fastq_manifest.map { ["all", it] }
        IMPORT_FASTQ ( ch_fastq_manifest )
    }

    if (ch_sra_artifact != null) {
        ch_sra_artifact = IMPORT_FASTQ.out
    }

    // FASTQ check
    CHECK_FASTQ_TYPE ( ch_sra_artifact )

    // Feature generation: Denoising for cleanup
    if (start_process != "clustering") {
        DENOISE_DADA2 ( CHECK_FASTQ_TYPE.out )
        ch_denoised_qzas = DENOISE_DADA2.out.table_seqs
    }

    // Feature generation: Clustering
    if (flag_get_ref) {
        DOWNLOAD_REF_SEQS ()
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
        DOWNLOAD_CLASSIFIER ()
        ch_trained_classifier = DOWNLOAD_CLASSIFIER.out
    }

    if (flag_get_ref_taxa) {
        DOWNLOAD_REF_TAXONOMY ()
        ch_taxa_ref_qza = DOWNLOAD_REF_TAXONOMY.out
    }

    ch_to_classify = CLUSTER_CLOSED_OTU.out.seqs
                        .combine ( ch_trained_classifier )
                        .combine ( ch_otu_ref_qza )
                        .combine ( ch_taxa_ref_qza )

    CLASSIFY_TAXONOMY ( ch_to_classify )

    CLUSTER_CLOSED_OTU.out.table
        .join ( CLASSIFY_TAXONOMY.out.taxonomy_qza )
        .set { ch_qza_to_collapse }

    COLLAPSE_TAXA ( ch_qza_to_collapse )
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