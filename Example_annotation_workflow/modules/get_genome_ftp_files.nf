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

include { gen_ftp_file_name } from './utils.nf'

process GET_GENOME_FTP_FILES {
    label 'local'
    tag "genome_ftp:${species}"
    storeDir "${params.cacheDir}/${species}/RAW_GFF3/"

    input:
        tuple val(species), val(common), val(feature_build), val(ens_version)
        val(base_ftp_url)

    output:
        tuple val(species), val(common), val(feature_build), val(ens_version),
            path(compressed_genome), emit: genome_gff3, 
            optional:false
        tuple val(species), val(common), val(feature_build), val(ens_version),
            path("{*-regulatory*.gz,*-EMAR*.gz,*-motif*.gz}"), 
            emit: associated_features, optional: true

    script:
        genome_gff_file_url = gen_ftp_file_name(base_ftp_url, species, feature_build, ens_version, 'genome')
        compressed_genome = "${species}-genome.gff3.gz"
        regulatory_file_url = gen_ftp_file_name(base_ftp_url, species, feature_build, ens_version, 'regulation')
        compressed_reg = "${species}-regulatory.gff3.gz"
        emar_file_url = gen_ftp_file_name(base_ftp_url, species, feature_build, ens_version, 'EMAR')
        compressed_emar = "${species}-EMAR.gff3.gz"
        motif_file_url = gen_ftp_file_name(base_ftp_url, species, feature_build, ens_version, 'motif')
        compressed_motif = "${species}-motif.gff3.gz"
        """
        sh ${params.scripts_dir}/download_ftp.sh ${genome_gff_file_url} ${compressed_genome}
        sh ${params.scripts_dir}/download_ftp.sh ${regulatory_file_url} ${compressed_reg}
        sh ${params.scripts_dir}/download_ftp.sh ${emar_file_url} ${compressed_emar}
        sh ${params.scripts_dir}/download_ftp.sh ${motif_file_url} ${compressed_motif}
        """
}

