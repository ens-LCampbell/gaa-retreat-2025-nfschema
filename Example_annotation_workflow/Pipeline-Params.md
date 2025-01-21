# GAA-Retreat, Breakout8: NXF params validation

nf-schema validation example schema

## Pipeline runtime options

A generic sample schema for this workflow

| Parameter | Description | Type | Default | Required | Hidden |
|-----------|-----------|-----------|-----------|-----------|-----------|
| `base_ftp_url` | Base Ensembl FTP URL hosting GFF3 files (Genomic, Regulation, Motif, EMAR) | `string` | https://ftp.ensembl.org/pub | True |  |
| `run_example_demo` | Dummy param to run the full workflow. | `boolean` | True | True |  |
| `adam_version` | Version of adam genomics (linked to <tag>) | `string` | 0.30.0--0 |  |  |
| `scripts_dir` | Path location of workflow scripts | `string` | ./scripts |  | True |

## Input/output options

Define where the pipeline should find input data and save output data.

| Parameter | Description | Type | Default | Required | Hidden |
|-----------|-----------|-----------|-----------|-----------|-----------|
| `input_csv` | Input metadata, containing species, build and ensembl version information. | `string` |  | True |  |
| `outdir` | The output directory where the results will be saved. | `string` | ./demo_outdir | True |  |

## Generic options

Less common options for the pipeline, typically set in a config file.

| Parameter | Description | Type | Default | Required | Hidden |
|-----------|-----------|-----------|-----------|-----------|-----------|
| `user` | User name linked to current User `whoami`. | `string` | lcampbell | True |  |
| `email` | Email address to send log trace report. | `string` |  |  |  |
| `send_report` | Enable trace report email report. | `boolean` |  |  |  |
| `cacheDir` | Location of cache directory to store intermediate. | `string` | ./cache |  |  |
| `trace_report_suffix` | Suffix to add to the trace report filename. Format: yyyy-MM-dd_HH-mm-ss. | `string` | validation-breakout-work-trace |  | True |
