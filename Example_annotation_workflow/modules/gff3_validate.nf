// See the NOTICE file distributed with this work for additional information
// regarding copyright ownership.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// include { generate_feature_filename } from 'utils.nf'

process GFF3_VALIDATION {
    tag "genome_tools:${species}-genome.valid.gff3"
    label 'genome_tools'
    storeDir "${params.cacheDir}/${species}/VALID_GFF3/"

    input:
        tuple val(species), val(common), val(feature_build), val(ens_version), 
            path(compressed_genome, stageAs: "compressed.gff3.gz")
    output:
        tuple val(species), val(build_version), path(out_gff3), emit: valid_gff3

    script:
        build_version = "${feature_build}-${ens_version}"
        out_gff3 = "${species}-${feature_build}-${ens_version}-genome.valid.gff3"
        """
        gunzip -c compressed.gff3.gz > ${out_gff3}
        gt gff3validator ${out_gff3}
        """
        // out_gff3 = "${species}-genome.valid.gff3"
        // gunzip -c compressed.gff3.gz > temp.gff3
        // gt gff3 -tidy -sort -force -o ${out_gff3} temp.gff3
        // rm temp.gff3
}
