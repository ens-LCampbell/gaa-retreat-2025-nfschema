// See the NOTICE file distributed with this work for additional information
// regarding copyright ownership.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


nextflow.enable.dsl=2
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// VALIDATE INPUTS
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
include { validateParameters; paramsSummaryLog; paramsSummaryMap; samplesheetToList } from 'plugin/nf-schema'

// Validate input parameters
validateParameters()
log.info paramsSummaryLog(workflow)

//Print param summary map:
println paramsSummaryMap(workflow)

include { GET_GENOME_FTP_FILES } from './modules/get_genome_ftp_files.nf'
include { CONVERT_TO_PARQUET } from './modules/convert_to_parquet.nf'
include { COMBINE_PARQUET_PARTS } from './modules/combine_parquet_parts.nf'
include { PARQUET_TO_FEATURES as TSS_FEATURES } from './modules/parquet_to_features.nf'
include { PARQUET_TO_FEATURES as GENE_FEATURES } from './modules/parquet_to_features.nf'
include { PARQUET_TO_FEATURES as CDS_COUNTS } from './modules/parquet_to_features.nf'
include { PARQUET_TO_FEATURES as MERGED_EXONS } from './modules/parquet_to_features.nf'
include { CREATE_ANNOTATION_DB } from './modules/create_annotation_db.nf'
include { GFF3_VALIDATION as GENOMIC_GFF3_VALID } from './modules/gff3_validate.nf'
// include { GFF3_VALIDATION as OTHERFEAT_GFF3_VALID } from './modules/gff3_validate.nf'

workflow {
    if (params.run_example_demo == true ){
        Channel.fromList(samplesheetToList(params.input_csv, "${projectDir}/Sample_input_schema.json"))
                .flatten()
                .map { row -> [sp_name:row.species, common_name:row.common, feature_build:row.build, ens_version:row.ensembl_version]}
                .set { demo_metadata }
            demo_metadata.each{ d-> d.view()}

        GET_GENOME_FTP_FILES(demo_metadata, params.base_ftp_url)
            genome_features = GET_GENOME_FTP_FILES.out.genome_gff3
            other_features = GET_GENOME_FTP_FILES.out.associated_features
            // genome_features.view()
            // other_features.view()

        // Perform some basic GFF3 file fomart validation with genome-tools cli
        GENOMIC_GFF3_VALID(genome_features)
            valid_genome_gff3 = GENOMIC_GFF3_VALID.out.valid_gff3
        // OTHERFEAT_GFF3_VALID(other_features)
        //     valid_othfeats_gff3 = OTHERFEAT_GFF3_VALID.out.valid_gff3
        
        // Convert genomic GFF3 to parquet format via adam genomics:
        parquet_meta = CONVERT_TO_PARQUET(valid_genome_gff3).parquet_partition

        // Convert parquet parts into combined single parquet file
        genome_parquet = COMBINE_PARQUET_PARTS(parquet_meta, "genomic").combined_parquet

        // Generate feature outputs (parquet + BED) files from genomic parquet and specific feature queries: 
        // Gene features
        gene_ch_output = GENE_FEATURES(genome_parquet, "Gene").features
            gene_ch_output
                .map { it -> [sp_name:it[0], build_version:it[1]]}
                .set { gene_parquet_meta }
                // gene_parquet_meta.view()
        
        // Gene features
        tss_ch_output = TSS_FEATURES(genome_parquet, "TSS").features
            tss_ch_output
                .map { it -> [sp_name:it[0], build_version:it[1]]}
                .set { tss_parquet_meta }

        // CDS features
        cds_counts_ch_output = CDS_COUNTS(genome_parquet, "CDS_Counts").features
            cds_counts_ch_output
                .map { it -> [sp_name:it[0], build_version:it[1]]}
                .set { cds_counts_meta }     

        // Exon features
        merged_exons_ch_output = MERGED_EXONS(genome_parquet, "MergedExons").features
            merged_exons_ch_output
                .map { it -> [sp_name:it[0], build_version:it[1]]}
                .set { merged_exons_parquet_meta }
        
        // Collapse dummy meta across features
        prepared_features = gene_parquet_meta.concat(
                tss_parquet_meta,
                cds_counts_meta,
                merged_exons_parquet_meta,
            )
            .unique().collect().flatten()
            map { it -> [sp_name:it[0], build_version:it[1]]}
            // prepared_features.view()

        // Generate the final Annotation database via create_annotation_db and above feature parquets
        output = CREATE_ANNOTATION_DB(prepared_features)
        output.view()
    }
}
