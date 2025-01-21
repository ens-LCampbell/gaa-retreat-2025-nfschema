/*
See the NOTICE file distributed with this work for additional information
regarding copyright ownership.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

-~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-    Nextflow config file
-~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-    Default config options for all compute environments
-----------------------------------------------------------------------------------------
-*/

// Set minimum required Nextflow version, stopping execution if current version does not match
nextflowVersion = '!>=24.04'

RUNDIR = System.getenv("NXF_WORK") ?: "$PWD"
NXF_WORK = System.getenv("NXF_WORK") ?: "$PWD/work"
TEMP_DIR = System.getenv("NXF_TEMP") ?: "$PWD/tmp"

plugins {
  id 'nf-schema@2.2.0'
}

validation {
  help {
    enabled = true
    validation.failUnrecognisedParams = true // default: false
  }
}

// valid param definitions
params {

    // Pipeline run options:
    base_ftp_url = "https://ftp.ensembl.org/pub"
    run_example_demo = true
    adam_version = null
    scripts_dir = "scripts"

    // Input/output options:
    input_csv = null
    outdir = null

    // Generic options:
    user = null
    email = "${params.user}@ebi.ac.uk"
    send_report = null
    cacheDir = "$NXF_WORK/cache"
    trace_report_suffix = null
}
