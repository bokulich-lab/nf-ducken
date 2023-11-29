#!/usr/bin/env nextflow
/*
========================================================================================
    nf-16s-pipe
========================================================================================
    Github : https://github.com/lina-kim/nf-16s-pipe
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    VALIDATE & PRINT PARAMETER SUMMARY
========================================================================================
*/

include { PIPE_16S_IMPORT_INPUT } from './workflows/pipe_16s_import'
include { PIPE_16S_DOWNLOAD_INPUT } from './workflows/pipe_16s_download'

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

workflow NF_PIPE_16S {
    
    if (!(params.pipeline_type)) {
        exit 1, 'pipeline_type parameter is required!'
    }

    if (params.pipeline_type == 'import') {
        PIPE_16S_IMPORT_INPUT ()

    } else if (params.pipeline_type == 'download') {
        PIPE_16S_DOWNLOAD_INPUT ()

    } else {
        exit 1, 'pipeline_type parameter values can only be either \"import\" or \"download\"!'
        
    }
     
}

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

workflow {
    NF_PIPE_16S ()
}