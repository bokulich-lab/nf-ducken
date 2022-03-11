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
    ch_inp_ids = file("${params.inp_id_file}", checkIfExists: true)
} else {
    exit 1, 'Input file with sample accession numbers does not exist or is not specified!'
}

/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

include { GENERATE_METADATA_ARTIFACT } from '../modules/generate_metadata_artifact'

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

workflow 16S_PIPE {
    GENERATE_METADATA_ARTIFACT ( ch_inp_ids )
    GENERATE_METADATA_ARTIFACT.out.view()
}

/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/

// TODO implement functions
workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}