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
    ch_dada2_table = Channel.fromPath( "${params.denoised_table}", checkIfExists: true )
    ch_dada2_seqs  = Channel.fromPath( "${params.denoised_seqs}",  checkIfExists: true )
    start_process  = "clustering"
} else if (params.fastq_manifest) {
    ch_fastq_manifest = Channel.fromPath( "${params.fastq_manifest}",
                                          checkIfExists: true )
    start_process = "fastq_import"

    if (params.phred_offset) {
        if (params.phred_offset == 64 || params.phred_offset == 33) {
            val_phred_offset = params.phred_offset
        } else {
            exit 1, 'The only valid PHRED offset values are 33 or 64!'
        }
    } else {
        val_phred_offset = 33
    }
} else {
    start_process = "id_import"
}

// Required user inputs
switch (start_process) {
    case "id_import":
        if (params.inp_id_file) {       // TODO shift to input validation module
            ch_inp_ids        = Channel.fromPath( "${params.inp_id_file}", checkIfExists: true )
            val_email         = params.email_address
            ch_fastq_manifest = Channel.empty()
            val_phred_offset  = Channel.empty()
        } else {
            exit 1, 'Input file with sample accession numbers does not exist or is not specified!'
        }
        break

    case "fastq_import":
        ch_inp_ids = Channel.empty()
        val_email  = Channel.empty()
        println "Skipping FASTQ download..."
        break

    case "clustering":
        ch_inp_ids        = Channel.empty()
        val_email         = Channel.empty()
        ch_fastq_manifest = Channel.empty()
        val_phred_offset  = Channel.empty()
        println "Skipping DADA2..."
        break
}

// Navigate user-input parameters necessary for pre-clustering steps
if (start_process != "clustering") {
    if (params.read_type) {
        val_read_type = params.read_type
    } else {
        exit 1, 'Read type parameter is required!'
    }
} else {
    val_read_type = Channel.empty()
}

if (params.otu_ref_file) {
    flag_get_ref    = false
    val_otu_ref_url = ""
    ch_otu_ref_qza  = Channel.fromPath( "${params.otu_ref_file}",
                                        checkIfExists: true )
} else {
    flag_get_ref    = true
    val_otu_ref_url = params.otu_ref_url
}

if (params.trained_classifier) {
    flag_get_classifier        = false
    val_trained_classifier_url = ""
    ch_trained_classifier      = Channel.fromPath( "${params.trained_classifier}",
                                                   checkIfExists: true )
} else {
    flag_get_classifier        = true
    val_trained_classifier_url = params.trained_classifier_url
}

// Required parameters with given defaults
val_trunc_len        = params.trunc_len
val_trunc_q          = params.trunc_q
val_taxa_level       = params.taxa_level
val_cluster_identity = params.cluster_identity


/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

include { GENERATE_ID_ARTIFACT; GET_SRA_DATA;
          CHECK_FASTQ_TYPE; IMPORT_FASTQ      } from '../modules/get_sra_data'
include { DENOISE_DADA2                       } from '../modules/denoise_dada2'
include { CLUSTER_CLOSED_OTU;
          DOWNLOAD_REF_SEQS                   } from '../modules/cluster_vsearch'
include { CLASSIFY_TAXONOMY; COLLAPSE_TAXA;
          DOWNLOAD_CLASSIFIER                 } from '../modules/classify_taxonomy'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

workflow PIPE_16S {
    // Download
    GENERATE_ID_ARTIFACT ( ch_inp_ids )
    GET_SRA_DATA (
        val_email,
        GENERATE_ID_ARTIFACT.out
        )

    if (val_read_type == "single") {
        ch_sra_artifact = GET_SRA_DATA.out.single
    } else if (val_read_type == "paired") {
        ch_sra_artifact = GET_SRA_DATA.out.paired
    } else {
        ch_sra_artifact = Channel.empty()
    }

    IMPORT_FASTQ (
        ch_fastq_manifest,
        val_read_type,
        val_phred_offset
        )

    if (start_process == "fastq_import") {
        ch_sra_artifact = IMPORT_FASTQ.out
    }

    // FASTQ check
    CHECK_FASTQ_TYPE (
        val_read_type,
        ch_sra_artifact
        )

    // Feature generation: Denoising for cleanup
    DENOISE_DADA2 (
        CHECK_FASTQ_TYPE.out,
        val_read_type,
        val_trunc_len,
        val_trunc_q
        )

    if (!(start_process == "clustering")) {
        ch_dada2_table = DENOISE_DADA2.out.table
        ch_dada2_seqs  = DENOISE_DADA2.out.rep_seqs
    }

    // Feature generation: Clustering
    if (flag_get_ref) {
        DOWNLOAD_REF_SEQS ( val_otu_ref_url )
        ch_otu_ref_qza = DOWNLOAD_REF_SEQS.out
    }

    CLUSTER_CLOSED_OTU (
        ch_dada2_table,
        ch_dada2_seqs,
        ch_otu_ref_qza,
        val_cluster_identity
        )

    // Classification
    if (flag_get_classifier) {
        DOWNLOAD_CLASSIFIER ( val_trained_classifier_url )
        ch_trained_classifier = DOWNLOAD_CLASSIFIER.out
    }

    CLASSIFY_TAXONOMY (
        ch_trained_classifier,
        CLUSTER_CLOSED_OTU.out.seqs
        )

    COLLAPSE_TAXA (
        CLUSTER_CLOSED_OTU.out.table,
        CLASSIFY_TAXONOMY.out.taxonomy_qza,
        val_taxa_level
        )
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