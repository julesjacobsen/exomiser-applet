#!/bin/bash
# exomiser first
set -e -x -o pipefail

main() {

    echo "Value of Exomiser Docker image: '$docker_image'"
    echo "Value of analysis_file: '$analysis_file'"
    echo "Value of vcf: '$vcf'"
    echo "Value of config: '$config'"
#    echo "Value of genome_data (dir): '$genome_data'"
#    echo "Value of phenotype_data (dir): '$phenotype_data'" 

    dx download "$docker_image" -o docker_image
    dx download "$config" -o application.properties
    dx download "$analysis_file" -o analysis_file
    dx download "$vcf" -o vcf
#    dx download "$genome_data" -o genome_data.zip
#    dx download "$phenotype_data" -o phenotype_data.zip
  
#    echo "Downloading genome and phenotype directories"
#    dx download "$genome_data" -o genome_data --recursive
#    dx download "$phenotype_data" -o phenotype_data --recursive

#    echo "Preparing Exomiser data directory"
#    mkdir -p /exomiser-data 
#    cp -r genome_data/* /exomiser-data/
#    cp -r phenotype_data/* /exomiser-data/

    echo "Exomiser data in resources directory:"
    ls -lh /resources

    # Fixing permissions so Exomiser's 'nonroot' user can read   
    chmod -R a+rX /resources
    
    docker load < docker_image
    
    outdir=/home/dnanexus/results
    mkdir -p "$outdir"    

    echo "Running Exomiser"
    docker run --rm \
        -v /home/dnanexus:/home/dnanexus \
        -v /resources:/exomiser-data \
        exomiser/exomiser-cli:14.0.0-distroless \
        --analysis /home/dnanexus/analysis_file \
        --output-directory "$outdir" \
        --exomiser.data-directory=/exomiser-data \
        --spring.config.location=/home/dnanexus/application.properties

    echo "Uploading results"
    html=$(dx upload "$outdir"/*.html --brief)
    json=$(dx upload "$outdir"/*.json --brief)

    dx-jobutil-add-output html "$html" --class=file
    dx-jobutil-add-output json "$json" --class=file
}
