#!/bin/bash

set -euo pipefail

usage() {
    echo "Usage: $0 <table_mapping1> <table_mapping2> ... <output_db_path>"
    echo "Example:"
    echo "  $0 'gene:data/human/features/gene' 'tss:data/human/features/tss' /data/db/human_annotation.db"
    echo
    echo "Positional Arguments:"
    echo "  table_mapping   A table mapping in the format 'TABLE_NAME:PARQUET_FILE_PATH'"
    echo "  output_db_path  Path to the output DuckDB file (must end with .db or .duckdb)"
    exit 1
}

if [ "$#" -lt 2 ]; then
    echo "Error: At least one table mapping and an output DB path are required."
    usage
fi

OUTPUT_DB="${@: -1}"

if [[ ! "$OUTPUT_DB" =~ \.(db|duckdb)$ ]]; then
    echo "Error: Output database path must end with '.db' or '.duckdb'."
    exit 1
fi

SQL_SCRIPT=""

for MAPPING in "${@:1:$#-1}"; do
    if [[ ! "$MAPPING" =~ ^[^:]+:.+ ]]; then
        echo "Error: Invalid table mapping format '$MAPPING'. Expected 'TABLE_NAME:PARQUET_FILE_PATH'."
        exit 1
    fi

    TABLE_NAME="${MAPPING%%:*}"
    PARQUET_PATH="${MAPPING#*:}"

    if [[ -z "$TABLE_NAME" || -z "$PARQUET_PATH" ]]; then
        echo "Error: TABLE_NAME or PARQUET_FILE_PATH is empty in mapping '$MAPPING'."
        exit 1
    fi

    if [[ ! -f "$PARQUET_PATH" ]]; then
        echo "Error: Parquet file '$PARQUET_PATH' does not exist."
        exit 1
    fi

    SANITIZED_TABLE_NAME=$(printf "%q" "$TABLE_NAME")
    SANITIZED_PARQUET_PATH=$(printf "%q" "$PARQUET_PATH")

    SQL_SCRIPT+="CREATE TABLE $SANITIZED_TABLE_NAME AS SELECT * FROM read_parquet('$SANITIZED_PARQUET_PATH');\n"
done

echo -e "$SQL_SCRIPT" | duckdb "$OUTPUT_DB" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "DuckDB database created successfully at: $OUTPUT_DB"
else
    echo "Failed to create DuckDB database."
    exit 1
fi