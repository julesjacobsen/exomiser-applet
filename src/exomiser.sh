#!/bin/bash
# exomiser first

main() {

    echo "Value of Exomiser Docker image: '$docker_image'"
    echo "Value of analysis_file: '$analysis_file'"
    echo "Value of vcf: '$vcf'"
    echo "Value of config: '$config'"
    echo "Value of genome_data: '$genome_data'"
    echo "Value of phenotype_data: '$phenotype_data'" 

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

    dx download "$docker_image" -o docker_image
    dx download "$config" -o application.properties
    dx download "$analysis_file" -o analysis_file
    dx download "$vcf" -o vcf
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

    # Fill in your application code here.
    #
    # To report any recognized errors in the correct format in
    # $HOME/job_error.json and exit this script, you can use the
    # dx-jobutil-report-error utility as follows:
    #
    #   dx-jobutil-report-error "My error message"
    #
    # Note however that this entire bash script is executed with -e
    # when running in the cloud, so any line which returns a nonzero
    # exit code will prematurely exit the script; if no error was
    # reported in the job_error.json file, then the failure reason
    # will be AppInternalError with a generic error message.
    
    docker load < docker_image
    
    outdir=/home/dnanexus/results
    mkdir -p "$outdir"    

    echo "Running Exomiser"
    docker run --rm \
        -v /home/dnanexus:/home/dnanexus \
        -v /exomiser-data:/exomiser-data \
        exomiser/exomiser-cli:14.0.0-distroless \
        --analysis /home/dnanexus/analysis_file \
        --output-directory /home/dnanexus/results \
        --exomiser.data-directory=/exomiser-data \
        --spring.config.location=/home/dnanexus/application.properties

                            
    # The following line(s) use the dx command-line tool to upload your file
    # outputs after you have created them on the local file system.  It assumes
    # that you have used the output field name for the filename for each output,
    # but you can change that behavior to suit your needs.  Run "dx upload -h"
    # to see more options to set metadata.

    html=$(dx upload "$outdir"/*.html --brief)
    json=$(dx upload "$outdir"/*.json --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output html "$html" --class=file
    dx-jobutil-add-output json "$json" --class=file
}
