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

process CONVERT_TO_PARQUET {
    label 'adam'
    tag "adam_convert_parquet:${species}"
    storeDir "${params.cacheDir}/${species}"
    
    input:
        tuple val(species), val(build_version), path(valid_gff3)

    output:
        tuple val(species), val(build_version), path("Parquet_partitions/"), emit: parquet_partition

    script:
        """
        adam-submit transformFeatures ${valid_gff3} ./Parquet_partitions
		"""
}