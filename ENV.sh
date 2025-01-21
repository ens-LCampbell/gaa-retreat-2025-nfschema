#!/usr/bin/bash

cp /homes/lcampbell/bin/duckdb /homes/$USER/bin/duckdb
NXF_SINGULARITY_NEW_PID_NAMESPACE=false
export PATH=$PATH:/homes/$USER/bin NXF_SINGULARITY_NEW_PID_NAMESPACE

## Obtain nf-core v3.1.2:
# To be shared on during the breakout!! 

## Don't forget to load nextflow:
# module load nextflow/24.04.3
