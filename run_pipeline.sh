#!/bin/bash

## usage: ./run_pipeline <path/to/assembly/directory> <path/to/results/directory>



# path to folder containing genome assemblies
ASSEMBLY_DIRECTORY="$1"
OUTPUT_DIRECTORY="$2"

######################
###### RUN MLST ######
######################
# this script runs mlst on all the assemblies in a folder and writes all the results to a tsv file mlst_summary.tsv in
# the MLST_results folder within the user-specfied results directory
# prior to running, create mamba/conda env with provided .yml file, then activate it
# usage: ./run_mlst.sh ASSEMBLY_DIRECTORY OUTPUT_DIRECTORY


mkdir ${OUTPUT_DIRECTORY}/MLST_results
output_file=${OUTPUT_DIRECTORY}/MLST_results/mlst_summary.tsv

# create or truncate the output file (if exists, will clear it)
> "$output_file"

# function to extract filename from the full path
get_filename() {
    filename=$(basename "$1")
    echo "$filename"
}

# run mlst on every .fna or .fna.gz file in samples folder
for assembly_file in "$ASSEMBLY_DIRECTORY"/*.fasta*; do
    echo "Running MLST for $(basename "$assembly_file")..."
    
    # Run MLST for the current assembly file and append results to output file
    mlst --nopath "$assembly_file" >> "$output_file"
done

echo "MLST analysis completed for all samples. Results written to $output_file."

###############################
######### RUN CHECKM ##########
###############################

# this script runs checkm on all the assemblies in a folder and writes all the results to a tsv file checkm_quality.tsv in
# the checkm_results folder within the user-specfied results directory
# prior to running, create mamba/conda env with provided .yml file, then activate it
# usage: ./run_checkm.sh ASSEMBLY_DIRECTORY OUTPUT_DIRECTORY

# List all taxonomic groups and filter for entries containing "Salmonella enterica"
mkdir ${OUTPUT_DIRECTORY}/checkm_results

# List all taxonomic groups and filter for entries containing "Salmonella enterica"
checkm taxon_list | grep salmonella_enterica_reference

# Set the taxonomic rank to species for "Salmonella enterica" and retrieve marker genes
checkm taxon_set species "Salmonella enterica" Se.markers

# Analyze marker genes with a minimum length of 30 base pairs, filter the output, and save it in FASTA format
checkm analyze Se.markers ${ASSEMBLY_DIRECTORY} ${OUTPUT_DIRECTORY}/checkm_results -x fasta

# Perform quality assessment using CheckM and save the output to a file named "checkm.tax.qa.out"
checkm qa -f ${OUTPUT_DIRECTORY}/checkm/checkm.tax.qa.out -o 1 Se.markers ${OUTPUT_DIRECTORY}/checkm_results

# Use 'sed' to substitute multiple spaces with a single tab in the quality assessment output file, then save the result to "quality.tsv"
sed 's/ \+ /\t/g' ${OUTPUT_DIRECTORY}/checkm/checkm.tax.qa.out > ${OUTPUT_DIRECTORY}/checkm_results/checkm_quality.tsv

rm Se.markers

echo "Checkm finished running successfully on all samples. Results written to ${OUTPUT_DIRECTORY}/checkm_results/checkm_quality.tsv"

################################
######## RUN GTDB-TK ###########
################################

# this script runs mlst on all the assemblies in a folder and writes all the results to a tsv file gtdbtk.bac120.summary.tsv in
# the gtdbtk_results folder within the user-specfied results directory.
# prior to running, create mamba/conda env with provided .yml file, then activate it
# usage: ./run_gtdbtk.sh ASSEMBLY_DIRECTORY OUTPUT_DIRECTORY

mkdir ${OUTPUT_DIRECTORY}/gtdbtk_results
GTDBTK_DATA_PATH="/gtdbtk_data"

export GTDBTK_DATA_PATH

gtdbtk classify_wf --genome_dir ${ASSEMBLY_DIRECTORY} \
--out_dir ${OUTPUT_DIRECTORY}/gtdbtk_results \
--extension fasta \
--cpus 10 --mash_db ./

echo "GTDB-TK finished running successfully on assemblies in $(basename ${ASSEMBLY_DIRECTORY})"
echo "GTDB-TK taxonomic results written to ${OUTPUT_DIRECTORY}/gtdbtk_results/gtdbtk.bac120.summary.tsv"
