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

process CREATE_ANNOTATION_DB {
    label 'local'
    tag "annotation:${species}"
    storeDir "${params.outdir}/${species}"

    input:
        tuple val(species), val(build_version)

    output:
        tuple val(species), val(build_version), path(annotation_database)

    script:
        feature_location = "${params.cacheDir}/${species}"
        prefix = "${species}-${build_version}"
        annotation_database = "${prefix}-annotation.db"
        """
        ${params.scripts_dir}/create_annotation_db.sh \
        'gene:${feature_location}/${prefix}-Gene-features.parquet' \
        'tss:${feature_location}/${prefix}-TSS-features.parquet' \
        'cds_counts:${feature_location}/${prefix}-CDS_Counts-features.parquet' \
        'merged_exons:${feature_location}/${prefix}-MergedExons-features.parquet' \
        ./${annotation_database}
        """
}