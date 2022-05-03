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
if (start_process == "id_import") {
    if (params.inp_id_file) {       // TODO shift to input validation module
        ch_inp_ids = Channel.fromPath( "${params.inp_id_file}", checkIfExists: true )
        val_email  = params.email_address
    } else {
        exit 1, 'Input file with sample accession numbers does not exist or is not specified!'
    }
} else if (start_process == "fastq_import") {
    ch_inp_ids = Channel.empty()
    println "Skipping FASTQ download..."
} else if (start_process == "clustering") {
    ch_inp_ids = Channel.empty()
    val_email  = Channel.empty()
    println "Skipping DADA2..."
}

// Navigate user-input parameters necessary for pre-clustering steps
if (start_process != "clustering") {
    val_email = Channel.empty()

    if (params.read_type) {
        val_read_type = params.read_type
    } else {
        exit 1, 'Read type parameter is required!'
    }

    if (params.trunc_len) {
        val_trunc_len = params.trunc_len
    } else {
        val_trunc_len = 0
    }

    if (params.trunc_q) {
        val_trunc_q = params.trunc_q
    } else {
        val_trunc_q = 2
    }
}

if (params.otu_ref_file) {
    if (params.otu_ref_file.endsWith(".qza")) {
        ch_otu_ref_qza = Channel.fromPath( "${params.otu_ref_file}", checkIfExists: true )
    } else {  // TODO modify to add RESCRIPt workflow later
        exit 1, 'OTU reference file does not exist or is not specified!'
    }
} else {   // TODO modify to include eventual download + RESCRIPt workflow later
    exit 1, 'OTU reference file does not exist or is not specified!'
}

if (params.trained_classifier) {
    if (params.trained_classifier.endsWith(".qza")) {
        ch_trained_classifier = Channel.fromPath( "${params.trained_classifier}", checkIfExists: true )
    } else {
        exit 1, 'Feature classifier file does not exist or is not specified!'
    }
} else {   // TODO modify to include eventual download + custom feature classifier training
    exit 1, 'Feature classifier file does not exist or is not specified!'
}

// Required parameters with given defaults
if (params.taxa_level) {    // TODO validate to ensure integer
    val_taxa_level = params.taxa_level
} else {
    val_taxa_level = 5
}


/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

include { GENERATE_ID_ARTIFACT; GET_SRA_DATA;
          CHECK_FASTQ_TYPE; IMPORT_FASTQ      } from '../modules/get_sra_data'
include { DENOISE_DADA2                       } from '../modules/denoise_dada2'
include { CLUSTER_CLOSED_OTU                  } from '../modules/cluster_vsearch'
include { CLASSIFY_TAXONOMY; COLLAPSE_TAXA    } from '../modules/classify_taxonomy'

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
    CLUSTER_CLOSED_OTU (
        ch_dada2_table,
        ch_dada2_seqs,
        ch_otu_ref_qza
        )

    // Classification
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