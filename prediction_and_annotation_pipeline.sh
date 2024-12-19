#!/bin/bash

# USAGE: ./gene_prediction.sh </path/to/data/directory> <path/to/results/directory>
# This pipeline requires two inputs:
# 1. path to a data directory containing all assemblies in FASTA format
# 2. path to a directory where you want your final output directory saved (this directory must already exist, this script will not create it for you)

# prior to running this script, create a mamba/conda environment (whatever your preference is)
# using the .yml file included in the main branch. It includes all software you need to run this pipeline.
# instructions for set up included in README.md. Activate this environment before running this script.


######################################
### Gene prediction using Prodigal ###
######################################

# Prior to running this script, you should navigate to a working directory where you want your results output saved
data_directory=$1
results_directory=$2


# Make overarching pipeline results directory within the results directory specified by CLI
mkdir ${results_directory}/pipeline_output
# create results directory for gene prediction
mkdir ${results_directory}/pipeline_output/prediction_results

# loop through sample genomes
for sample_file in "$data_directory"/*.fasta; do
    # get sample name without extension
    sample_name=$(basename "$sample_file" .fasta)
    sample_name=${sample_name%%_filtered}

    # create subdirectories for each sample
    mkdir ${results_directory}/pipeline_output/prediction_results/"$sample_name"
    mkdir ${results_directory}/pipeline_output/prediction_results/"$sample_name"/cds
    mkdir ${results_directory}/pipeline_output/prediction_results/"$sample_name"/ssu

    # run barnapp and extract 16S rRNA
    barrnap "$sample_file" | grep "Name=16S_rRNA;product=16S ribosomal RNA" \
    > ${results_directory}/pipeline_output/prediction_results/"$sample_name"/ssu/"$sample_name"_16S.gff

    # print message to terminal
    echo "Barrnap successfully run on $sample_name"

    # bedtools extraction for 16S rRNA for downstream taxonoic classification
    bedtools getfasta -fi "$sample_file" -bed ${results_directory}/pipeline_output/prediction_results/"$sample_name"/ssu/"$sample_name"_16S.gff \
    -fo ${results_directory}/pipeline_output/prediction_results/"$sample_name"/ssu/"$sample_name"_16S.fa

    # print message to terminal
    echo "16s nucleotide sequences extracted from $sample_name"

    # run prodigal and extract CDS
    prodigal -i "$sample_file" -c -m -f gff -o ${results_directory}/pipeline_output/prediction_results/"$sample_name"/cds/"$sample_name"_cds.gff 2>&1 \
    | tee ${results_directory}/pipeline_output/prediction_results/"$sample_name"/cds/"$sample_name"_log.txt

    # print message to terminal
    echo "Prodigal successfully run on $sample_name"

    # bedtools extraction for CDS
    bedtools getfasta -fi "$sample_file" -bed ${results_directory}/pipeline_output/prediction_results/"$sample_name"/cds/"$sample_name"_cds.gff \
    -fo ${results_directory}/pipeline_output/prediction_results/"$sample_name"/cds/"$sample_name"_cds.fa

    # print message to terminal
    echo "Coding region nucleotide sequences extracted from $sample_name"

    # cleanup excess files not needed for further downstream analyses
    rm -v "$data_directory"/*.fai

    # print message to terminal
    echo "Gene prediction complete for $sample_name"

done


####################################################################################
### AMR Finder Plus for Antibiotics Resistance, virulence, stress response genes ###
####################################################################################
mkdir ${results_directory}/pipeline_output/amr_raw_results

# Pull updated databases
# force update option forces an overwrite of a previously downloaded database with
# the newest version
amrfinder -u --force_update

# Run AMR finder on each predicted coding sequence
for sample in ${data_directory}/*; do
    sample_name=$(basename ${sample} .fasta)
    sample_name=${sample_name%%_filtered}
    #echo ${sample_name}

    for sample_file in ${results_directory}/pipeline_output/prediction_results/${sample_name}/cds/*.fa; do
        # echo ${sample_file}
        sample=$(basename ${sample_file})
        sample=${sample%%_cds.fa}
        # echo ${sample}

        # sample_file=$(basename ${sample_file})
        amrfinder -n ${sample_file} --plus > ${results_directory}/pipeline_output/amr_raw_results/${sample}.tsv
    done

    echo "AMRFinder completed for ${sample_name}"
done


### Convert TSV output to GFF3 by parsing and extracting the new information to a new file

mkdir ${results_directory}/pipeline_output/amr_annotations

for input_file in ${results_directory}/pipeline_output/amr_raw_results/*.tsv; do
    filename=$(basename ${input_file} .tsv)
    filename=${filename%%_amr}

    while IFS=$'\t' read -r -a line; do
        prot_identifier="${line[0]}"
        seqid="${line[1]}"
        source="AMRFinder Plus"
        type="CDS"
        start="${line[2]}"
        end="${line[3]}"
        score="."
        strand="${line[4]}"
        phase="."

        name="${line[5]}"
        seq_name="${line[6]}"
        scope="${line[7]}"
        el_type="${line[8]}"
        el_subtype="${line[9]}"
        class="${line[10]}"
        subclass="${line[11]}"
        method="${line[12]}"
        target_len="${line[13]}"
        ref_seq_len="${line[14]}"
        cov_ref="${line[15]}"
        iden_ref_seq="${line[16]}"
        len="${line[17]}"
        acc_closest_species="${line[18]}"
        closest_seq="${line[19]}"
        HMM_id="${line[20]}"
        HMM_des="${line[21]}"


        attributes="ID=$seqid;Gene:$name;Note: Element type:$el_type,Element subtype:$el_subtype,Class:$class,Subclass:$subclass,Method:$method,Accession of closet species:$acc_closest_species,HMM_id:$HMM_id,HMM Description:$HMM_des"
        echo -e "$seqid\t$source\t$type\t$start\t$end\t$score\t$strand\t$phase\t$attributes" >> ${results_directory}/pipeline_output/amr_annotations/${filename}.gff3
    done < <(tail -n +2 ${input_file})
    echo "AMR TSV converted to GFF3 for ${filename}"
done
rm -r ${results_directory}/pipeline_output/amr_raw_results
echo "amr_raw_results temporary directory removed"



####################################
### Gene Annotation using Eggnog ###
####################################
conda deactivate

### Must create and activate new conda environment with newer version of python
## (old environment has python 2.7 to work with other software, this version of eggonog needs 3.8 at least)
conda create -n eggnog python=3.8 -y
conda activate eggnog
conda install -c bioconda eggnog-mapper=2.1.7 -y


# make directory for annotation results
mkdir ${results_directory}/pipeline_output/eggnog_annotations


download_eggnog_data.py -y


create_dbs.py -m diamond --dbname bacteria --taxa Bacteria


for directory in ${results_directory}/pipeline_output/prediction_results/*; do
    sample_name=$(basename ${directory})
    # echo ${sample_name}
    emapper.py --itype CDS -m diamond --translate /
    -i ${results_directory}/pipeline_output/prediction_results/${sample_name}/cds/${sample_name}_cds.fa \
    --output ${sample_name} --output_dir ${results_directory}/pipeline_output/eggnog_annotations --decorate_gff yes

    echo "Eggnog run successfully on ${sample_name}"
done

#########################################
## Merge annotations to one GFF3 file ###
#########################################

mkdir ${results_directory}/pipeline_output/FINAL_ANNOTATIONS

for sample_file in "$data_directory"/*.fasta; do
    # get sample name without extension
    sample_name=$(basename "$sample_file" .fasta)
    sample_name=${sample_name%%_filtered}
    # echo ${sample_name}

    # Merge AMR and 16S predictions
    cat ${results_directory}/pipeline_output/amr_annotations/${sample_name}.gff3 ${results_directory}/pipeline_output/prediction_results/${sample_name}/ssu/${sample_name}_16S.gff > ${results_directory}/pipeline_output/FINAL_ANNOTATIONS/${sample_name}.gff3

    cat ${results_directory}/pipeline_output/eggnog_annotations/${sample_name}.emapper.decorated.gff ${results_directory}/pipeline_output/FINAL_ANNOTATIONS/${sample_name}.gff3 > ${results_directory}/pipeline_output/FINAL_ANNOTATIONS/${sample_name}_merged.gff3

    rm ${results_directory}/pipeline_output/FINAL_ANNOTATIONS/${sample_name}.gff3

    sort -k1,1 -t$'\t' ${results_directory}/pipeline_output/FINAL_ANNOTATIONS/${sample_name}_merged.gff3 > ${results_directory}/pipeline_output/FINAL_ANNOTATIONS/${sample_name}_final.gff3

    tail -n +2 ${results_directory}/pipeline_output/FINAL_ANNOTATIONS/${sample_name}_final.gff3 > temp_file && mv temp_file ${results_directory}/pipeline_output/FINAL_ANNOTATIONS/${sample_name}_final.gff3

    echo "Merged all GFF3 annotation files for ${sample_name}. Final annotated file located at ${results_directory}/pipeline_output/FINAL_ANNOTATIONS/${sample_name}_final.gff3"

    rm ${results_directory}/pipeline_output/FINAL_ANNOTATIONS/*merged*
done

conda deactivate























