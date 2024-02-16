// Validation Script for nextflow.config parameters

// Function to validate the contents of a TSV file including column names
def validateTsvContents(String filePath, int expectedColumns, List<String> validIdColumnNames = null) {
    File file = new File(filePath)
    if (!file.exists()) {
        throw new FileNotFoundException("File does not exist: $filePath")
    }

    file.withReader { reader ->
        def lineNumber = 0
        reader.eachLine { line ->
            def columns = line.split('\t')
            if (lineNumber == 0 && validIdColumnNames != null) {
                if (!validIdColumnNames.any { it.equalsIgnoreCase(columns[0].replaceAll(" ", "")) }) {
                    throw new IllegalArgumentException("First column name in $filePath is not valid. It must be one of ${validIdColumnNames.join(', ')}")
                }
            }
            if (columns.size() != expectedColumns) {
                throw new IllegalArgumentException("Expected $expectedColumns columns, but found ${columns.size()} in $filePath")
            }
            lineNumber++
        }
    }
}

// Custom exception class
class ParameterValidationException extends RuntimeException {
    ParameterValidationException(String message) {
        super(message)
    }
}

// Assertion function
def assertParam(value, typeConstraints, rangeConstraints = null, errorMessage = "") {
    boolean typeCheckPassed = typeConstraints.any { it.isInstance(value) }
    
    boolean rangeCheckPassed = true
    if (rangeConstraints != null) {
        rangeCheckPassed = rangeConstraints.any { constraint ->
            if (constraint instanceof Closure) {
                constraint(value)
            } else {
                value == constraint
            }
        }
    }

    if (!typeCheckPassed || !rangeCheckPassed) {
        throw new ParameterValidationException(errorMessage)
    }
}

// Define a method to validate parameters
def validateParams(params) {

  // Validation for general parameters
  assertParam(params.outdir, [String], null, "outdir must be a String")
  assertParam(params.read_type, [String], ["paired", "single"], "read_type must be either 'paired' or 'single'")
  assertParam(params.pipeline_type, [String], ["import", "download"], "pipeline_type must be either 'import' or 'download'")

  // Valid ID column names
  List<String> validIdColumnNames = [
    "id", "sampleid", "sample-id", "featureid", "feature-id", "#SampleID", "#OTUID", "sample_name"].collect { it.toLowerCase().replaceAll(" ", "") }

  try {
    // Check if the pipeline types and then specific parameters to them
    if (params.pipeline_type == 'import') {
      if (params.fastq_manifest) {
        validateTsvFile(params.fastq_manifest)
        validateTsvContents(params.fastq_manifest, params.read_type == "paired" ? 3 : 2, validIdColumnNames)
      } else {
        exit 1, 'fastq_manifest parameter is required!'
      }

    } else {
      if (params.inp_id_file) {
        validateTsvFile(params.inp_id_file)
        validateTsvContents(params.inp_id_file, 1, validIdColumnNames)
      } else {
        exit 1, 'inp_id_file parameter is required!'
      }

      if (!(params.email_address)) {
        exit 1, 'email_address parameter is required!'
      }

    }

    if (params.primer_file) {
        validateTsvFile(params.primer_file)
        validateTsvContents(params.primer_file, params.read_type == "paired" ? 3 : 2, validIdColumnNames)
    }

	} catch (AssertionError e) {
    println "TSV file content validation failed: ${e.message}"
    System.exit(1)
	}

	////////////////////////////////////////
	// Validation for cutadapt parameters //
	////////////////////////////////////////
	def cutadapt = params.cutadapt

	assertParam(cutadapt.num_cores, [Integer], null, "cutadapt.num_cores must be an Integer")
	assertParam(cutadapt.error_rate, [BigDecimal, Integer], [{ it >= 0 && it <= 1 }], "cutadapt.error_rate must be a Float or Integer with a value between 0 and 1")
	assertParam(cutadapt.times, [Integer], [{ it >= 1 }], "cutadapt.times must be an Integer with a value of 1 or above")
	assertParam(cutadapt.overlap, [Integer], [{ it >= 1 }], "cutadapt.overlap must be an Integer with a value of 1 or above")
	assertParam(cutadapt.minimum_length, [Integer], [{ it >= 1 }], "cutadapt.minimum_length must be an Integer with a value of 1 or above")
	assertParam(cutadapt.quality_cutoff_5end, [Integer], [{ it >= 0 }], "cutadapt.quality_cutoff_5end must be an Integer with a value of 0 or above")
	assertParam(cutadapt.quality_cutoff_3end, [Integer], [{ it >= 0 }], "cutadapt.quality_cutoff_3end must be an Integer with a value of 0 or above")
	assertParam(cutadapt.quality_base, [Integer], [33, 64], "cutadapt.quality_base must be either 33 or 64 representing Phred encoding")
	assertParam(cutadapt.indels, [String], ["True", "False"], "cutadapt.indels must be either 'True' or 'False'")
	assertParam(cutadapt.match_read_wildcards, [String], ["True", "False"], "cutadapt.match_read_wildcards must be either 'True' or 'False'")
	assertParam(cutadapt.match_adapter_wildcards, [String], ["True", "False"], "cutadapt.match_adapter_wildcards must be either 'True' or 'False'")
	assertParam(cutadapt.discard_untrimmed, [String], ["True", "False"], "cutadapt.discard_untrimmed must be either 'True' or 'False'")

	if (cutadapt.max_expected_errors != null) {
			assertParam(cutadapt.max_expected_errors, [Integer], [{ it >= 0 }], "cutadapt.max_expected_errors must be an Integer with a value of 0 or above")
	}

	if (cutadapt.max_n != null) {
			assertParam(cutadapt.max_n, [Integer, BigDecimal], [{ it instanceof Integer && it >= 0 }, { it instanceof BigDecimal && it >= 0 && it <= 1 }], "cutadapt.max_n must be either an Integer with a value of 0 or above, or a Float with a value between 0 and 1 representing a fraction of the read length")
	}

	/////////////////////////////////////
	// Validation for DADA2 parameters //
	/////////////////////////////////////
	def dada2 = params.dada2
	assertParam(dada2.trunc_len, [Integer], [{ it >= 0 }], "dada2.trunc_len must be a non-negative Integer")
	assertParam(dada2.trim_left, [Integer], [{ it >= 0 }], "dada2.trim_left must be a non-negative Integer")
	assertParam(dada2.max_ee, [BigDecimal, Integer], [{ it >= 0.0 }], "dada2.max_ee must be a Float or Integer representing a non-negative number")
	assertParam(dada2.trunc_len_f, [Integer], [{ it >= 0 }], "dada2.trunc_len_f must be a non-negative Integer")
	assertParam(dada2.trunc_len_r, [Integer], [{ it >= 0 }], "dada2.trunc_len_r must be a non-negative Integer")
	assertParam(dada2.trim_left_f, [Integer], [{ it >= 0 }], "dada2.trim_left_f must be a non-negative Integer")
	assertParam(dada2.trim_left_r, [Integer], [{ it >= 0 }], "dada2.trim_left_r must be a non-negative Integer")
	assertParam(dada2.max_ee_f, [BigDecimal, Integer], [{ it >= 0.0 }], "dada2.max_ee_f must be a Float or Integer representing a non-negative number")
	assertParam(dada2.max_ee_r, [BigDecimal, Integer], [{ it >= 0.0 }], "dada2.max_ee_r must be a Float or Integer representing a non-negative number")
	assertParam(dada2.min_overlap, [Integer], [{ it >= 4 }], "dada2.min_overlap must be an Integer with a value of 4 or above")
	assertParam(dada2.trunc_q, [Integer], [{ it >= 0 }], "dada2.trunc_q must be a non-negative Integer")
	assertParam(dada2.pooling_method, [String], ["independent", "pseudo"], "dada2.pooling_method must be one of ['independent', 'pseudo']")
	assertParam(dada2.chimera_method, [String], ["consensus", "none", "pooled"], "dada2.chimera_method must be one of ['consensus', 'none', 'pooled']")
	assertParam(dada2.min_fold_parent_over_abundance, [BigDecimal, Integer], [{ it >= 1.0 }], "dada2.min_fold_parent_over_abundance must be a Float or Integer with a value of 1.0 or greater")
	assertParam(dada2.num_threads, [Integer], [{ it >= 0 }], "dada2.num_threads must be a non-negative Integer")
	assertParam(dada2.num_reads_learn, [Integer], [{ it >= 0 }], "dada2.num_reads_learn must be a non-negative Integer")
	assertParam(dada2.hashed_feature_ids, [String], ["True", "False"], "dada2.hashed_feature_ids must be either 'True' or 'False'")


	///////////////////////////////////////
	// Validation for vsearch parameters //
	/////////////////////////////////////// 
	def vsearch = params.vsearch
	assertParam(vsearch.perc_identity, [BigDecimal, Integer], [{ it > 0 && it <= 1 }], "vsearch.perc_identity must be a Float or Integer with a value greater than 0 and up to 1 inclusive")
	assertParam(vsearch.strand, [String], ["plus", "both"], "vsearch.strand must be one of ['plus', 'both']")
	assertParam(vsearch.num_threads, [Integer], [{ it >= 0 && it <= 256 }], "vsearch.num_threads must be an Integer with a value between 0 and 256 inclusive")

	//////////////////////////////////////////
	// Validation for classifier parameters //
	//////////////////////////////////////////
	def classifier = params.classifier
	assertParam(classifier.method, [String], ["sklearn", "blast", "vsearch"], "classifier.method must be one of ['sklearn', 'blast', 'vsearch']")
	assertParam(classifier.reads_per_batch, [String, Integer], ["auto", "all", ""], "classifier.reads_per_batch must be 'auto', 'all', '', or an Integer")
	assertParam(classifier.num_jobs, [Integer], null, "classifier.num_jobs must be an Integer, either -1 (for using all CPUs), 1 (for no parallel computing), or a positive integer; or less than -1 for specific CPU usage")
	assertParam(classifier.pre_dispatch, [String], null, "classifier.pre_dispatch must be a String")
	assertParam(classifier.confidence, [BigDecimal, Integer, String], [{ it instanceof Number && it >= 0 && it <= 1 }, "disable"], "classifier.confidence must be a Float, Integer or String with a numerical value between 0 and 1 inclusive, or the string 'disable'")
	assertParam(classifier.read_orientation, [String], ["auto", "forward", "reverse"], "classifier.read_orientation must be one of ['auto', 'forward', 'reverse']")

	//////////////////////////////////////////
	// Validation for uchime_ref parameters //
	//////////////////////////////////////////
	def uchime_ref = params.uchime_ref
	assertParam(uchime_ref.dn, [BigDecimal, Integer], [{ it >= 0.0 }], "uchime_ref.dn must be a Float or Integer with a value of 0.0 or above")
	assertParam(uchime_ref.min_diffs, [Integer], [{ it >= 1 }], "uchime_ref.min_diffs must be an Integer with a value of 1 or above")
	assertParam(uchime_ref.min_div, [BigDecimal, Integer], [{ it >= 0.0 }], "uchime_ref.min_div must be a Float or Integer with a value of 0.0 or above")
	assertParam(uchime_ref.min_h, [BigDecimal, Integer], [{ it >= 0.0 && it <= 1.0 }], "uchime_ref.min_h must be a Float or Integer with a value between 0.0 and 1.0 inclusive")
	assertParam(uchime_ref.xn, [BigDecimal, Integer], [{ it > 1.0 }], "uchime_ref.xn must be a Float or Integer with a value greater than 1.0")
	assertParam(uchime_ref.num_threads, [Integer], [{ it >= 0 && it <= 256 }], "uchime_ref.num_threads must be an Integer with a value between 0 and 256 inclusive")

	///////////////////////////////////////////////
	// Validation for other top-level parameters //
	///////////////////////////////////////////////
	assertParam(params.taxa_level, [Integer], [{ it >= 1 && it <= 7 }], "taxa_level must be an Integer between 1 and 7 inclusive, representing the range up to the species level")
	assertParam(params.phred_offset, [Integer], [33, 64], "phred_offset must be either 33 or 64")
	assertParam(params.vsearch_chimera, [Boolean], [true, false], "vsearch_chimera must be true or false")
	assertParam(params.otu_ref_url, [String], null, "otu_ref_url must be a String")
	assertParam(params.trained_classifier_url, [String], null, "trained_classifier_url must be a String")
	assertParam(params.taxonomy_ref_url, [String], null, "taxonomy_ref_url must be a String")
	assertParam(params.qiime_release, [String], null, "qiime_release must be a String")
	assertParam(params.fastqc_release, [String], null, "fastqc_release must be a String")
	assertParam(params.multiqc_container, [String], null, "multiqc_container must be a String")

}

def validateTsvFile(filePath) {
   assert filePath.toLowerCase().endsWith(".tsv") : "File must be a TSV file, but it has the wrong extension: ${filePath}"  
}