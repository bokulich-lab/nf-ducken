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

include { IMPORT   } from './workflows/import'
include { DOWNLOAD } from './workflows/download'

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

workflow NF_DUCKEN {
    
    if (!(params.pipeline_type)) {
        exit 1, 'pipeline_type parameter is required!'
    }

    if (params.pipeline_type == 'import') {
        IMPORT ()
    } else if (params.pipeline_type == 'download') {
        DOWNLOAD ()
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
    NF_DUCKEN ()
}

workflow.onComplete {
    if (workflow.profile.contains('conda')) {
        println("Workflow completed. Cleaning up Conda environments...")

        def cleanupCommand = "rm -rf $workflow.workDir/conda/"
        def proc = cleanupCommand.execute()
        proc.waitForProcessOutput()

        println("Cleanup completed.")
    }
}