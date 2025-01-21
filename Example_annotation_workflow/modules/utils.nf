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


def gen_ftp_file_name(base_ftp, species, build, version, feature_type) {

    String file_path = ""
    String file_name = ""
    String full_file_url = ""
    String species_lc = species.toLowerCase()
    String v_version = "v" + version
    if (feature_type == "genome" ) {
        file_path = [base_ftp,"current_gff3",species_lc].join("/")
        file_name = [species,build,version,"gff3.gz"].join(".")       
    }
    else if (feature_type == "regulation" ) {
        file_path = [base_ftp,"current_regulation",species_lc,build,"annotation"].join("/")
        file_name = [species,build,"regulatory_features",v_version,"gff3.gz"].join(".")
    }
    else if (feature_type == "EMAR" ) {
        file_path = [base_ftp,"current_regulation",species_lc,build,"annotation"].join("/")
        file_name = [species,build,"EMARs",v_version,"gff.gz"].join(".")
    }
    else if (feature_type == "motif" ) {
        file_path = [base_ftp,"current_regulation",species_lc,build,"annotation"].join("/")
        file_name = [species,build,"motif_features",v_version,"gff3.gz"].join(".")
    }
    full_file_url = file_path + "/" + file_name
    return full_file_url
}


def generate_feature_filename(String parquet, feat_type){
    List split_str = parquet.split('\\.')
    String prefix = split_str[0]
    String file_name = "${prefix}.${feat_type}-features.parquet"
    return file_name
}