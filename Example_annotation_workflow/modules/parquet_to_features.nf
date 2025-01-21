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

process PARQUET_TO_FEATURES {
    label 'local'
    tag "query_parquet:${feature_type}:${species}"
    storeDir "${params.cacheDir}/${species}"

    input:
        tuple val(species), val(build_version), path(combined_parquet_file)
        val(feature_type)
    
    output:
        tuple val(species), val(build_version), 
            path(feature_parquet_file),
            path(bed_file), emit: features

    script:
        outfile_prefix = "${species}-${build_version}-${feature_type}"
        feature_parquet_file = "${outfile_prefix}-features.parquet"
        bed_file = "${outfile_prefix}-features.bed"

        if (feature_type =~ "Gene"){
            query_sql = "${params.scripts_dir}/query_gene.sql"
            query_bed = "${params.scripts_dir}/query_gene_bed.sql"
        }
        else if (feature_type =~ "TSS"){
            query_sql = "${params.scripts_dir}/query_tss.sql"
            query_bed = "${params.scripts_dir}/query_tss_bed.sql"
        }
        else if (feature_type =~ "MergedExons"){
            query_sql = "${params.scripts_dir}/query_merged_exons.sql"
            query_bed = "${params.scripts_dir}/query_merged_exons_bed.sql"
        }
        else if (feature_type =~ "CDS_Counts"){
            query_sql = "${params.scripts_dir}/query_cds_counts.sql"
            query_bed = "${params.scripts_dir}/query_cds_counts_bed.sql"
        }
        """
        sh ${params.scripts_dir}/query_genomic_annotation.sh \
            ${query_sql} \
            ${combined_parquet_file} \
            ${feature_parquet_file}

        sh ${params.scripts_dir}/query_genomic_annotation.sh \
            ${query_bed} \
            ${combined_parquet_file} \
            ${bed_file}
        """
}