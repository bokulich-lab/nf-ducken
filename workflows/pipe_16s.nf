/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

// Validate input parameters

// Check input path parameters to see if they exist
// params.input may be: folder, samplesheet, fasta file, and therefore should not appear here (because tests only for "file")

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
if (params.denoised_table && params.denoised_seqs) {
    ch_dada2_table = Channel.fromPath( "${params.denoised_table}", checkIfExists: true )
    ch_dada2_seqs  = Channel.fromPath( "${params.denoised_seqs}",  checkIfExists: true )
    skip_dada2     = true
}

if (params.fastq_dir) {
    ch_fastq_dir  = Channel.fromPath( "${params.fastq_dir}",
                                      type: "dir",
                                      checkIfExists: true )
    skip_download = true
}

// Required user inputs
if (params.inp_id_file) {
    ch_inp_ids = Channel.fromPath( "${params.inp_id_file}", checkIfExists: true )
} else if (skip_dada2) {
    ch_inp_ids = Channel.empty()
    println "Skipping DADA2..."
} else {
    exit 1, 'Input file with sample accession numbers does not exist or is not specified!'
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

val_email      = params.email_address
val_read_type  = params.read_type
val_trunc_len  = params.trunc_len
val_trunc_q    = params.trunc_q
val_taxa_level = params.taxa_level


/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

include { GENERATE_ID_ARTIFACT; GET_SRA_DATA; CHECK_FASTQ_TYPE } from '../modules/get_sra_data'
include { DENOISE_DADA2                                        } from '../modules/denoise_dada2'
include { CLUSTER_CLOSED_OTU                                   } from '../modules/cluster_vsearch'
include { CLASSIFY_TAXONOMY, COLLAPSE_TAXA                     } from '../modules/classify_taxonomy'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

workflow PIPE_16S {
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

    CHECK_FASTQ_TYPE (
        val_read_type,
        ch_sra_artifact
        )

    DENOISE_DADA2 (
        CHECK_FASTQ_TYPE.out,
        val_read_type,
        val_trunc_len,
        val_trunc_q
        )

    if (!(ch_dada2_table) && !(ch_dada2_seqs)) {
        ch_dada2_table = DENOISE_DADA2.out.table
        ch_dada2_seqs  = DENOISE_DADA2.out.rep_seqs
    }

    CLUSTER_CLOSED_OTU (
        ch_dada2_table,
        ch_dada2_seqs,
        ch_otu_ref_qza
        )

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