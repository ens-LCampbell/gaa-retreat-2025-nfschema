# Some of the common commands when using nf-schema plugin:

# Creation of a schema (nextflow_schema.json)
nf-core pipelines schema build --dir ./

# Validation of a nextflow_schema.json against default parameters (nextflow.config)
nf-core pipelines schema lint --dir  .

# Validation of a input parameters against a nxf schema:
nf-core pipelines schema validate . nf-params.json
### Example: nf-params.json
```
{
  "base_ftp_url": "https://ftp.ensembl.org/pub",
  "run_example_demo": true,
  "adam_version": "1.0.1--0",
  "input_csv": "demo_input.csv",
  "outdir": "./demo_outdir",
  "trace_report_suffix": "demo-trace",
  "user": "$USER",
  "email": "lcampbell@ebi.ac.uk",
  "send_report": true
}
```
# Generation of documentation from a nextflow_schema.json
nf-core pipelines schema docs --dir . --output Pipeline-Params.md --format markdown

