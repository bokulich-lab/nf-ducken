// Validation Script for nextflow.config parameters

// Define a method to validate parameters
def validateParams(params) {

    // Validation for general parameters
    assert params.outdir instanceof String : "outdir must be a String, but it is of type ${params.outdir.getClass().getName()}"
    assert params.tracedir.startsWith("${params.outdir}") : "tracedir must be inside outdir, but it is of type ${params.tracedir.getClass().getName()}"

   // Validate tsv files
   try {
      if (params.fastq_manifest) {
         validateTsvFile(params.fastq_manifest)
         validateTsvContents(params.fastq_manifest, 3) // Replace 5 with your expected column count
      }

      if (params.primer_file) {
         validateTsvFile(params.primer_file)
         validateTsvContents(params.primer_file, 3)
      }

      if (params.inp_id_file) {
         validateTsvFile(params.inp_id_file)
         validateTsvContents(params.inp_id_file, 1)
      }

      println "TSV file content validation successful."
   } catch (AssertionError e) {
      println "TSV file content validation failed: ${e.message}"
      System.exit(1)
   }

    ////////////////////////////////////////
    // Validation for cutadapt parameters //
    ////////////////////////////////////////
    def cutadapt = params.cutadapt

    // cutadapt.num_cores
    assert cutadapt.num_cores instanceof Integer : "cutadapt.num_cores must be an Integer, but it is of type ${cutadapt.num_cores.getClass().getName()}"
    // cutadapt.error_rate
    assert (cutadapt.error_rate instanceof BigDecimal || cutadapt.error_rate instanceof Integer) &&  cutadapt.error_rate >= 0 && cutadapt.error_rate <= 1 : 
       "cutadapt.error_rate must be a BigDecimal or Integer with a value between 0 and 1, but it is of type ${cutadapt.error_rate.getClass().getName()} with a value of ${cutadapt.error_rate}"
    // cutadapt.times
    assert cutadapt.times instanceof Integer && cutadapt.times >= 1 : 
       "cutadapt.times must be an Integer with a value of 1 or above, but it is of type ${cutadapt.times.getClass().getName()} with a value of ${cutadapt.times}"
    // cutadapt.overlap
    assert cutadapt.overlap instanceof Integer && cutadapt.overlap >= 1 : 
       "cutadapt.overlap must be an Integer with a value of 1 or above, but it is of type ${cutadapt.overlap.getClass().getName()} with a value of ${cutadapt.overlap}"
    // utadapt.minimum_length
    assert cutadapt.minimum_length instanceof Integer && cutadapt.minimum_length >= 1 : 
       "cutadapt.minimum_length must be an Integer with a value of 1 or above, but it is of type ${cutadapt.minimum_length.getClass().getName()} with a value of ${cutadapt.minimum_length}"
    // cutadapt.quality_cutoff_5end
    assert cutadapt.quality_cutoff_5end instanceof Integer && cutadapt.quality_cutoff_5end >= 0 : 
       "cutadapt.quality_cutoff_5end must be an Integer with a value of 0 or above, but it is of type ${cutadapt.quality_cutoff_5end.getClass().getName()} with a value of ${cutadapt.quality_cutoff_5end}"
    // cutadapt.quality_cutoff_3end
    assert cutadapt.quality_cutoff_3end instanceof Integer && cutadapt.quality_cutoff_3end >= 0 : 
       "cutadapt.quality_cutoff_3end must be an Integer with a value of 0 or above, but it is of type ${cutadapt.quality_cutoff_3end.getClass().getName()} with a value of ${cutadapt.quality_cutoff_3end}"
    // cutadapt.quality_base
    assert cutadapt.quality_base instanceof Integer && cutadapt.quality_base >= 0 : 
       "cutadapt.quality_base must be an Integer with a value of 0 or above, but it is of type ${cutadapt.quality_base.getClass().getName()} with a value of ${cutadapt.quality_base}"
    // cutadapt.indels
    assert ["True", "False"].contains(cutadapt.indels) : "cutadapt.indels must be either 'True' or 'False'"
    // cutadapt.match_read_wildcards
    assert ["True", "False"].contains(cutadapt.match_read_wildcards) : "cutadapt.match_read_wildcards must be either 'True' or 'False'"
    // cutadapt.match_adapter_wildcards
    assert ["True", "False"].contains(cutadapt.match_adapter_wildcards) : "cutadapt.match_adapter_wildcards must be either 'True' or 'False'"
    // cutadapt.discard_untrimmed
    assert ["True", "False"].contains(cutadapt.discard_untrimmed) : "cutadapt.discard_untrimmed must be either 'True' or 'False'"
    // cutadapt.max_expected_errors
    if (cutadapt.max_expected_errors != null) {
        assert cutadapt.max_expected_errors instanceof Integer && cutadapt.max_expected_errors >= 0 : 
       "cutadapt.max_expected_errors must be an Integer with a value of 0 or above, but it is of type ${cutadapt.max_expected_errors.getClass().getName()} with a value of ${cutadapt.max_expected_errors}"
    }
    // cutadapt.max_n
    if (cutadapt.max_n != null) {
        assert cutadapt.max_n instanceof Integer && cutadapt.max_n >= 0 : 
       "cutadapt.max_n must be an Integer with a value of 0 or above, but it is of type ${cutadapt.max_n.getClass().getName()} with a value of ${cutadapt.max_n}"
    }

    /* TODO (if used in the future)
    adapter  = null
    front    = null
    anywhere = null

    adapter_f  = null
    front_f    = null
    anywhere_f = null
    adapter_r  = null
    front_r    = null
    anywhere_r = null
    */


    /////////////////////////////////////
    // Validation for DADA2 parameters //
    /////////////////////////////////////
    def dada2 = params.dada2
    // dada2.trunc_len
    assert dada2.trunc_len instanceof Integer && dada2.trunc_len >= 0 : 
       "dada2.trunc_len must be a non-negative Integer, but is ${dada2.trunc_len.getClass().getName()} with a value of ${dada2.trunc_len}"
    // dada2.trim_left
    assert dada2.trim_left instanceof Integer && dada2.trim_left >= 0 : 
       "dada2.trim_left must be a non-negative Integer, but is ${dada2.trim_left.getClass().getName()} with a value of ${dada2.trim_left}"
    // dada2.max_ee
    assert (dada2.max_ee instanceof BigDecimal) && dada2.max_ee >= 0.0 : 
       "dada2.max_ee must be a BigDecimal (Float) representing a non-negative number, but it is of type ${dada2.max_ee.getClass().getName()} with a value of ${dada2.max_ee}"

    // Paired-end reads
    // dada2.trunc_len_f
    assert dada2.trunc_len_f instanceof Integer && dada2.trunc_len_f >= 0 : 
       "dada2.trunc_len_f must be a non-negative Integer, but is ${dada2.trunc_len_f.getClass().getName()} with a value of ${dada2.trunc_len_f}"
    // dada2.trunc_len_r
    assert dada2.trunc_len_r instanceof Integer && dada2.trunc_len_r >= 0 : 
       "dada2.trunc_len_r must be a non-negative Integer, but is ${dada2.trunc_len_r.getClass().getName()} with a value of ${dada2.trunc_len_r}"
    // dada2.trim_left_f
    assert dada2.trim_left_f instanceof Integer && dada2.trim_left_f >= 0 : 
       "dada2.trim_left_f must be a non-negative Integer, but is ${dada2.trim_left_f.getClass().getName()} with a value of ${dada2.trim_left_f}"
    // dada2.trim_left_r
    assert dada2.trim_left_r instanceof Integer && dada2.trim_left_r >= 0 : 
       "dada2.trim_left_r must be a non-negative Integer, but is ${dada2.trim_left_r.getClass().getName()} with a value of ${dada2.trim_left_r}"
    // dada2.max_ee_f
    assert (dada2.max_ee_f instanceof BigDecimal) && dada2.max_ee_f >= 0.0 : 
       "dada2.max_ee_f must be a BigDecimal (Float) representing a non-negative number, but it is of type ${dada2.max_ee_f.getClass().getName()} with a value of ${dada2.max_ee_f}"
    // dada2.max_ee_r
    assert (dada2.max_ee_r instanceof BigDecimal) && dada2.max_ee_r >= 0.0 : 
       "dada2.max_ee_r must be a BigDecimal (Float) representing a non-negative number, but it is of type ${dada2.max_ee_r.getClass().getName()} with a value of ${dada2.max_ee_r}"
    // dada2.min_overlap
    assert dada2.min_overlap instanceof Integer && dada2.min_overlap >= 4 : 
       "dada2.min_overlap must be an Integer with a value of 4 or above, but is ${dada2.min_overlap.getClass().getName()} with a value of ${dada2.min_overlap}"

    // General parameters
    // dada2.trunc_q
    assert dada2.trunc_q instanceof Integer && dada2.trunc_q >= 0 : 
       "dada2.trunc_q must be a non-negative Integer, but is ${dada2.trunc_q.getClass().getName()} with a value of ${dada2.trunc_q}"
    // dada2.pooling_method
    assert dada2.pooling_method in ["independent", "pseudo"] : 
       "dada2.pooling_method must be one of ['independent', 'pseudo'], but is ${dada2.pooling_method}"
    // dada2.chimera_method
    assert dada2.chimera_method in ["consensus", "none", "pooled"] : 
       "dada2.chimera_method must be one of ['consensus', 'none', 'pooled'], but is ${dada2.chimera_method}"
    // dada2.min_fold_parent_over_abundance
    assert (dada2.min_fold_parent_over_abundance instanceof BigDecimal) && dada2.min_fold_parent_over_abundance >= 1.0 : 
       "dada2.min_fold_parent_over_abundance must be a BigDecimal (Float) with a value of 1.0 or greater, but it is of type ${dada2.min_fold_parent_over_abundance.getClass().getName()} with a value of ${dada2.min_fold_parent_over_abundance}"
    // dada2.num_threads
    assert dada2.num_threads instanceof Integer && dada2.num_threads >= 0 : 
       "dada2.num_threads must be a non-negative Integer, but is ${dada2.num_threads.getClass().getName()} with a value of ${dada2.num_threads}"
    // dada2.num_reads_learn
    assert dada2.num_reads_learn instanceof Integer && dada2.num_reads_learn >= 0 : 
       "dada2.num_reads_learn must be a non-negative Integer, but is ${dada2.num_reads_learn.getClass().getName()} with a value of ${dada2.num_reads_learn}"
    // dada2.hashed_feature_ids
    assert ["True", "False"].contains(dada2.hashed_feature_ids) : "dada2.hashed_feature_ids must be either 'True' or 'False', but is ${dada2.hashed_feature_ids.getClass().getName()}"


    ///////////////////////////////////////
    // Validation for vsearch parameters //
    /////////////////////////////////////// 
    def vsearch = params.vsearch
    // vsearch.perc_identity
    assert (vsearch.perc_identity instanceof BigDecimal || vsearch.perc_identity instanceof Integer) && vsearch.perc_identity > 0 && vsearch.perc_identity <= 1 : 
       "vsearch.perc_identity must be a BigDecimal (Float) or Integer with a value greater than 0 and up to 1 inclusive, but it is of type ${vsearch.perc_identity.getClass().getName()} with a value of ${vsearch.perc_identity}"
    // vsearch.strand
    assert vsearch.strand in ["plus", "both"] : "vsearch.strand must be one of ['plus', 'both']"
    // vsearch.num_threads
    assert vsearch.num_threads instanceof Integer && vsearch.num_threads >= 0 && vsearch.num_threads <= 256 : 
       "vsearch.num_threads must be an Integer with a value between 0 and 256 inclusive, but it is of type ${vsearch.num_threads.getClass().getName()} with a value of ${vsearch.num_threads}"


    //////////////////////////////////////////
    // Validation for classifier parameters //
    //////////////////////////////////////////
    def classifier = params.classifier
    // classifier.method
    assert classifier.method in ["sklearn", "blast", "vsearch"] : "classifier.method must be one of ['sklearn', 'blast', 'vsearch']"
    // classifier.reads_per_batch
    assert classifier.reads_per_batch in ["auto", "all", ""] || classifier.reads_per_batch instanceof Integer : "classifier.reads_per_batch must be 'auto', 'all', '', or an Integer"
    // classifier.num_jobs
    assert classifier.num_jobs instanceof Integer : "classifier.num_jobs must be an Integer, either -1 (for using all CPUs), 1 (for no parallel computing), or a positive integer; or less than -1 for specific CPU usage, but it is of type ${classifier.num_jobs.getClass().getName()} with a value of ${classifier.num_jobs}"
    // classifier.pre_dispatch
    assert classifier.pre_dispatch instanceof String : "classifier.pre_dispatch must be a String, but is ${classifier.pre_dispatch.getClass().getName()}"
    // classifier.confidence
    assert (classifier.confidence instanceof BigDecimal || classifier.confidence instanceof String || classifier.confidence instanceof Integer) && (classifier.confidence >= 0 && classifier.confidence <= 1) || classifier.confidence == "disable" : 
       "classifier.confidence must be a BigDecimal (Float), Integer or String with a numerical value between 0 and 1 inclusive, or the string 'disable', but it is of type ${classifier.confidence.getClass().getName()} with a value of ${classifier.confidence}"
    // classifier.read_orientation
    assert classifier.read_orientation in ["auto", "forward", "reverse"] : "classifier.read_orientation must be one of ['auto', 'forward', 'reverse']"


    //////////////////////////////////////////
    // Validation for uchime_ref parameters //
    //////////////////////////////////////////
    def uchime_ref = params.uchime_ref
    // uchime_ref.dn
    assert (uchime_ref.dn instanceof BigDecimal) && uchime_ref.dn >= 0.0 : 
       "uchime_ref.dn must be a BigDecimal (Float) with a value of 0.0 or above, but it is of type ${uchime_ref.dn.getClass().getName()} with a value of ${uchime_ref.dn}"
    // uchime_ref.min_diffs
    assert uchime_ref.min_diffs instanceof Integer && uchime_ref.min_diffs >= 1 : 
       "uchime_ref.min_diffs must be an Integer with a value of 1 or above, but it is of type ${uchime_ref.min_diffs.getClass().getName()} with a value of ${uchime_ref.min_diffs}"
    // uchime_ref.min_div
    assert (uchime_ref.min_div instanceof BigDecimal) && uchime_ref.min_div >= 0.0 : 
       "uchime_ref.min_div must be a BigDecimal (Float) with a value of 0.0 or above, but it is of type ${uchime_ref.min_div.getClass().getName()} with a value of ${uchime_ref.min_div}"
    // uchime_ref.min_h
    assert (uchime_ref.min_h instanceof BigDecimal) && uchime_ref.min_h >= 0.0 && uchime_ref.min_h <= 1.0 : 
       "uchime_ref.min_h must be a BigDecimal (Float) with a value between 0.0 and 1.0 inclusive, but it is of type ${uchime_ref.min_h.getClass().getName()} with a value of ${uchime_ref.min_h}"
    // uchime_ref.xn
    assert (uchime_ref.xn instanceof BigDecimal) && uchime_ref.xn > 1.0 : 
       "uchime_ref.xn must be a BigDecimal (Float) with a value greater than 1.0, but it is of type ${uchime_ref.xn.getClass().getName()} with a value of ${uchime_ref.xn}"
    // uchime_ref.num_threads
    assert uchime_ref.num_threads instanceof Integer && uchime_ref.num_threads >= 0 && uchime_ref.num_threads <= 256 : 
       "uchime_ref.num_threads must be an Integer with a value between 0 and 256 inclusive, but it is of type ${uchime_ref.num_threads.getClass().getName()} with a value of ${uchime_ref.num_threads}"


    ///////////////////////////////////////////
    // Validation for fastq_split parameters //
    ///////////////////////////////////////////
    def fastq_split = params.fastq_split
    // fastq_split.enabled
    //assert fastq_split.enabled in ["true", "false", null] : 
    //    "fastq_split.enabled must be 'true', 'false', or null, but is ${fastq_split.enabled}"
    // fastq_split.suffix
    assert fastq_split.suffix instanceof String : 
        "fastq_split.suffix must be a String, but is ${fastq_split.suffix.getClass().getName()} with a value of ${fastq_split.suffix}"
    // fastq_split.method
    assert fastq_split.method in ["sample"] || fastq_split.method instanceof Integer : 
        "fastq_split.method must be 'sample' or an Integer, but is ${fastq_split.method}"


    ///////////////////////////////////////////////
    // Validation for other top-level parameters //
    ///////////////////////////////////////////////
    // params.taxa_level
    assert params.taxa_level instanceof Integer && params.taxa_level >= 1: 
       "taxa_level must be an Integer >= 1, but is ${params.taxa_level.getClass().getName()} with a value of ${params.taxa_level}"
    // params.phred_offset
    assert params.phred_offset in [33, 64] : "phred_offset must be either 33 or 64"
    // params.vsearch_chimera
    assert params.vsearch_chimera in [true, false] : "vsearch_chimera must be true or false"


    // params.otu_ref_url
    assert params.otu_ref_url instanceof String : "otu_ref_url must be a String, but is ${params.otu_ref_url.getClass().getName()}"
    // params.trained_classifier_url
    assert params.trained_classifier_url instanceof String : "trained_classifier_url must be a String, but is ${params.trained_classifier_url.getClass().getName()}"
    // params.taxonomy_ref_url
    assert params.taxonomy_ref_url instanceof String : "taxonomy_ref_url must be a String, but is ${params.taxonomy_ref_url.getClass().getName()}"
    // params.qiime_release
    assert params.qiime_release instanceof String : "qiime_release must be a String, but is ${params.qiime_release.getClass().getName()}"
    // params.fastqc_release
    assert params.fastqc_release instanceof String : "fastqc_release must be a String, but is ${arams.fastqc_release.getClass().getName()}"
    // params.multiqc_container
    assert params.multiqc_container instanceof String : "multiqc_container must be a String, but is ${params.multiqc_container.getClass().getName()}"
}

// Call the validation method with the actual parameters
try {
    validateParams(params)
    println "Parameter validation successful."
} catch (AssertionError e) {
    println "Parameter validation failed: ${e.message}"
    System.exit(1)
}

// Function to validate the contents of a TSV file
def validateTsvContents(String filePath, int expectedColumns) {
    if (filePath != null) {
        File file = new File(filePath)
        assert file.exists() : "File does not exist: $filePath"

        file.eachLine { line ->
            def columns = line.split('\t')
            assert columns.size() == expectedColumns : "Expected $expectedColumns columns, but found ${columns.size()} in $filePath"
        }
    }
}

def validateTsvFile(filePath) {
   assert filePath.toLowerCase().endsWith(".tsv") : "File must be a TSV file, but it has the wrong extension: ${filePath}"  
}