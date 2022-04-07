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
if (params.inp_id_file) {
    ch_inp_ids = Channel.fromPath( "${params.inp_id_file}", checkIfExists: true )
} else {
    exit 1, 'Input file with sample accession numbers does not exist or is not specified!'
}

val_email = params.email_address
val_read_type = params.read_type

/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

include { GENERATE_ID_ARTIFACT; GET_SRA_DATA; CHECK_FASTQ_TYPE } from '../modules/get_sra_data'

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
//
//     if (val_read_type == "single") {
//         sra_artifact = GET_SRA_DATA.out.single
//     } elif (val_read_type == "paired") {
//         sra_artifact = GET_SRA_DATA.out.paired
//     }

//     switch(val_read_type) {
//         case "single":
//             sra_artifact = GET_SRA_DATA.out.single;
//             break;
//         case "paired":
//             sra_artifact = GET_SRA_DATA.out.paired;
//             break;
//         case default:   // Validation steps exist upstream to prevent this
//             false
//     }

//     CHECK_FASTQ_TYPE (
//         val_read_type,
//         sra_artifact
//         )
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