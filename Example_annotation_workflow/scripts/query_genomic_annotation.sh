#!/bin/bash

set -euo pipefail

if [[ $# -lt 3 ]]; then
    echo "Usage: $0  <sql-file> <genomic_annotation_parquet> <output_parquet>"
    exit 1
fi

SQL_FILE=$1
GENOMIC_ANNOTATION_PARQUET=$2
OUTPUT_PARQUET=$3

if [[ "${SQL_FILE##*.}" != "sql" ]]; then
    echo "Error: sql-file '$SQL_FILE' does not have a .sql extension."
    exit 1
fi

if [[ ! -f "$SQL_FILE" ]]; then
    echo "Error: SQL query file '$SQL_FILE' does not exist."
    exit 1
fi

if [[ ! -f "$GENOMIC_ANNOTATION_PARQUET" ]]; then
    echo "Error: Input file '$GENOMIC_ANNOTATION_PARQUET' does not exist."
    exit 1
fi

OUTPUT_DIR=$(dirname "$OUTPUT_PARQUET")
if [[ ! -w "$OUTPUT_DIR" ]]; then
    echo "Error: Output directory '$OUTPUT_DIR' is not writable."
    exit 1
fi

# Read SQL query from file
SQL_QUERY=$(<"$SQL_FILE")

# Replace placeholders in the SQL query with actual values
SQL_QUERY="${SQL_QUERY//\$genomic_annotation_parquet/$GENOMIC_ANNOTATION_PARQUET}"
SQL_QUERY="${SQL_QUERY//\$output/$OUTPUT_PARQUET}"

# Run query with DuckDB client
duckdb -c "${SQL_QUERY}"

echo "Query executed successfully. Output written to '$OUTPUT_PARQUET'."