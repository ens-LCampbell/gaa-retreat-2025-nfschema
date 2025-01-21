// See the NOTICE file distributed with this work for additional information
// regarding copyright ownership.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in wristing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

process COMBINE_PARQUET_PARTS {
    label 'local'
    tag "partitions-${gff3_type}:${species}"
    storeDir "${params.cacheDir}/${species}"
    
    input:
        tuple val(species), val(build_version), path(partition_dir)
        val(gff3_type)

    output:
        tuple val(species), val(build_version), path(combined_parquet_file), emit: combined_parquet

    script:
        combined_parquet_file = "${species}-${build_version}.${gff3_type}.combined.parquet"
        """
        duckdb -c "COPY (SELECT * FROM read_parquet('${partition_dir}/*.parquet')) TO '${combined_parquet_file}' (FORMAT PARQUET)"
		"""
}