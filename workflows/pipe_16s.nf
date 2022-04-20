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

// Input
if (params.denoised_table && params.denoised_seqs) {
    ch_dada2_table = Channel.fromPath( "${params.denoised_table}", checkIfExists: true )
    ch_dada2_seqs  = Channel.fromPath( "${params.denoised_seqs}",  checkIfExists: true )
    skip_dada2     = true
}

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

val_email = params.email_address
val_read_type = params.read_type
val_trunc_len = params.trunc_len
val_trunc_q = params.trunc_q


/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

include { GENERATE_ID_ARTIFACT; GET_SRA_DATA; CHECK_FASTQ_TYPE } from '../modules/get_sra_data'
include { DENOISE_DADA2                                        } from '../modules/denoise_dada2'
include { CLUSTER_CLOSED_OTU                                   } from '../modules/cluster_vsearch'

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