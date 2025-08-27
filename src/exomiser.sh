#!/bin/bash
# exomiser first

main() {

    echo "Value of Exomiser Docker image: '$docker_image'"
    echo "Value of analysis_file: '$analysis_file'"
    echo "Value of vcf: '$vcf'"
    echo "Value of config: '$config'"
    echo "Value of genome_data: '$genome_data'"
    echo "Value of phenotype_data: '$phenotype_data'" 

    dx download "$docker_image" -o docker_image
    dx download "$config" -o application.properties
    dx download "$analysis_file" -o analysis_file
    dx download "$vcf" -o sample.vcf.gz
    dx download "$genome_data" -o genome_data.zip
    dx download "$phenotype_data" -o phenotype_data.zip

    echo "Preparing Exomiser data"
    mkdir -p /exomiser-data

    echo "Unzipping genome data"
    unzip -q genome_data.zip -d /exomiser-data

    echo "Unzipping phenotype data" 
    unzip -q phenotype_data.zip -d /exomiser-data

    echo "Data contents:"
    ls -lh /exomiser-data

    # Fixing permissions so Exomiser's 'nonroot' user can read   
    chmod -R a+rX /exomiser-data

    docker load < docker_image
    
    outdir=/home/dnanexus/results
    mkdir -p "$outdir"    

    echo "Running Exomiser"
    docker run \
        -v /home/dnanexus:/home/dnanexus \
        -v /home/dnanexus/results:/app/classes/results \
        -v /exomiser-data:/exomiser-data \
        exomiser/exomiser-cli:14.0.0-distroless \
        --analysis /home/dnanexus/analysis_file \
        --vcf /home/dnanexus/sample.vcf.gz \
        --assembly hg38 \
        --output-directory /home/dnanexus/results \
        --exomiser.data-directory=/exomiser-data \
        --exomiser.hg38.data-version=2502 \
        --exomiser.phenotype.data-version=2502


#        --spring.config.location=/home/dnanexus/application.properties

    html=$(dx upload "$outdir"/*.html --brief)
    json=$(dx upload "$outdir"/*.json --brief)

    dx-jobutil-add-output html "$html" --class=file
    dx-jobutil-add-output json "$json" --class=file
}
