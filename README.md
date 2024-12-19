# Workflow-of-Nextflow

Data Cleaning and Assembly Workflow
This workflow script is a combination of individual scripts written by team members to assess read quality, trim reads, remove phiX, assess quality post-trimming, and assemble samples. It works on a set of input FASTQ files.

You must have a conda environment with the necessary dependencies to run this. Required is Python 3.8, FastQC, MultiQC, Trimmomatic, BBMap, SKESA, and Biopython (version 1.75).

Additionally you will need to have the filter.contigs.py file downloaded. To run properly, the code must be updated to point to this file wherever you have it stored.

Script Description
This script performs the following steps:

1. Runs fastQC on raw data (input fastq files)
2. Runs multiQC for a summary of previously generated fastQC files
3. Unzips compressed fastq files
4. Trims files with Trimmomatic
5. Runs fastQC on trimmed files
6. Runs multiQC for a summary of previously generated fastQC on trimmed files
7. Removes phiX contamination using BBMap
8. Runs fastQC on trimmed files with phiX removed
9. Runs multiQC for a summary of previously generated fastQC on trimmed files with phiX removed
10. Assembles cleaned files using SKESA
11. Filters assembled contigs using filter.contigs.py
    
Note:

1. this script creates several directories for data organization ('unzip', 'trim_data', 'fastqc_results', 'trimmed_no_phiX', 'fastqc_noPhiX_results', 'SKESA_Assembled', and 'SKESA_Filtered')
2. final results (cleaned and assembled reads in fasta format) are within the 'SKESA_filtered' folder

Instructions
1. Set Directories
2. Update 'inputDir' to the directory your FASTQ files are located.
3. Update all tool paths are set correctly based on your system configuration.
('FASTQC', 'MULTIQC', 'TRIMMOMATIC', 'BBDUK_SCRIPT', 'SKESA', and 'FILTER_SCRIPT')

Gene Prediction and Annotation - 
The following pipeline was created by Team D Group 2. The pipeline takes the path to a directory containing assembly FASTA files as argument 1 and a path to a directory where you want your results output. The pipeline will output a new directory called "pipeline_output" within the provided results path with the following substructure. An example below is shown with one assembly file.

The final annotated GFF3 files for each assembly can be found in the FINAL_ANNOTATIONS directory, but the other directories are kept in the pipeline_output folder in case the raw results are needed for other analyses in other workflows.

Environment Installation and Setup
Attached in this respository is phase_2.yml, which contains all software needed to run the pipeline script. To set up an environment with this software, download the phase_2.yml located in this repo, create a conda environment, and update it with the environment file.

Now you have a conda environment with all of the necessary packages and dependencies installed and you're ready to run the pipeline script!

Run the pipeline
Download the attached bash script prediction_and_annotation.sh. The script will only work properly if the script is in the working directory, which also contains the data directory with FASTA assemblies. Usage of this script is as follows:

The pipeline automates the entire process from prediction to annotation with no additional user input. Just run it and wait for the results! Below the individual steps in the pipeline are described in further detail.

Gene Prediction with Prodigal and Barrnap
This portion of the script reads in each of the FASTA assembly files in the input data directory. It will create a new directory called "prediction_results" with subdirectories for each input sample, with further subdirectories for the coding regions predicted by Prodigal and the 16S coding regions found using barrnap. The original output format of both Prodigal and barrnap is a .gff file containing the coordinate positions in the genome of these coding regions. For further downstream analysis in this script, bedtools is used to extract the actual coding sequences and place them in their respective directories for the corresponding sample.

Results from Prodigal and barrnap can be found in pipeline_output/prediction_results/<sample_name>/cds and pipeline_output/prediction_results/<sample_name>/ssu, respectively.

Functional Annotation with AMR Finder Plus and Eggnog
This portion of the script takes in input automatically from the prediction_results directory.

AMR Finder Plus
The extracted nucleotide sequences using the coding regions predicted from prodigal will first be searched using NCBI's AMRFinder Plus tool that uses NCBI's specially curated AMR database for antibiotic resistance, virulence, and stress response genes. The finding and annotation of these genes will help with further downstream analysis by other groups (genotyping and comparative genomics).

Final results from this step can be found in pipeline_output/amr_annotations. To begin with the TSV output of AMR Finder Plus is placed in a temporary directory, but once the pipeline converts this TSV to GFF3 format, the temporary directory will be deleted.

Eggnog
The extracted nucloetide sequences using the coding regions predicted from prodigal will then be searched against the eggnog database, which will be automatically downloaded in the script. EggnogV2.1.7 will be used in this pipeline to automatically obtain annotated GFF3 files for each coding region with a match in the database. The installation of eggnog-mapper with conda will create a directory called eggnog-mapper in the working directory.

This step will deactivate the original environment activated before running the script and create and activate a new one with the correct version of eggnog and corresponding python version all within the script. It will also automatically download the eggnog core database and create the correct Bacteria database from this. This step will take the longest as the database takes approximately an hour to download due to its large file size. Each file also takes a little over an hour to run (depending on exact file size). Progress will be printed to terminal as each sample finishes running.

Final Outputs
After both annotation softwares have run, the resultant GFF3 files for each sample will be merged to result in one annotated GFF3 file for each input sample, with the final results being found in pipeline_output/FINAL_ANNOTATIONS.

These GFF3 files with annotated genes will be used by later groups to aid in taxonomic classification and comparative genomics.

Genotyping, Taxonomic Classification, and Quality Assessment 
The following pipeline was created by Team D Group 3. It is designed to run the three steps: genotyping, taxonomic classification, and quality assesment sequentially on assembly files. Make sure your desired results directory is already created in order to run pipeline successfully.

IMPORTANT: Before Running Pipeline
Clone Github Repository
To ensure all necessary dependency files are in the proper working directory, clone this github repository to your local machine and perform all subsequent steps within this working directory. The pipeline allows you to specify input and output directories in other locations, but run the pipeline within this working directory.

Environment Installation and Setup
Attached in this respository is phase_3.yml, which contains all software needed to run the pipeline script. To set up an environment with this software, download the phase_3.yml located in this repo, create a conda environment, and update it with the environment file.

TDB Database download
Before running the pipeline, you need to have the GTDB database downloaded to your working directory (wherever you expect to run the pipeline from). This database requires ~84GB of free storage space and the download process can take several hours, which is why we have included the installation instructions outside of the pipeline. The external data must be downloaded (will download the most recent version, which at the time of writing this is R214) and unarchived.

This will leave you with a folder entitled gtdbtk_data in your working directory. Our pipeline assumes that a folder with this name is located in your working directory when you run the pipeline.

If this database is too computationally intensive for your workspace, you can always run your assembly files using GTDB-TK V 1.6.0 on the third-party webserver Kbase located here, but keep in mind if you don't have the database locally downloaded, the GTDB-TK step in the pipeline will fail (but others should still run fine as all steps in the pipeline are independent of one another). Note that the pipeline will also run GTDB-TK V 2.3.2, while the online option only supports V 1.6.0.

You are now ready to run the pipeline following the usage specified at the top of this page!
Genotyping with MLST
MLST will be run in the pipeline and take the path to the assembly data directory (ASSEMBLY_DIRECTORY) as input. It outputs a file "mlst_summary.tsv" in the MLST_results folder within the specified output directory. This script performs MLST analysis on all assemblies in the input folder and writes a summary of the final MLST genotyping results to a tsv file. MLST is a molecular typing method used to characterize isolates of bacterial species based on the sequences of several housekeeping genes – these results will appear in the output tsv file.

MLST documentation can be found here.

An example command can be found below. The assembly files must be in FASTA format and the pipeline assumes that they also have the ".fasta" file extension. The --nopath option strips filename paths from FILE column of the MLST output.

axonomic Classification with GTDB-TK
GTDB-TK will be run in the pipeline and take the path to assembly data directory (ASSEMBLY_DIRECTORY) and the path to your desired output directory as input. It will use GTDBK-TK's classify_wf workflow, which goes through 4 different steps: ani_screen, identify, align, and classify. The ani_screen step compares the genomes against a MASH database of GTDB representative genomes and then uses fastANI to verify the hits. If the hits are verified by fastANI, they don't proceed through the rest of the pipeline and are placed in the final summary TSV.

Results from this step are found with in the gtdbk_results folder within the user-specified output directory path. All classifications will be found in the file named "gtdbtk.bac120.summary.tsv".

GTDBK-TK classify_wf documentation can be found here.

Quality Assessment with CheckM
Checkm will be run in the pipeline and take the path to the assembly data directory (ASSEMBLY_DIRECTORY) and the path to your desired output directory as input. It will use the taxonomy workflow to search for the correct species level taxon and output a summary TSV of completion and contamination information for each input assembly file.



CheckM taxonomy worklfow documentation can be found here. The -x fasta option was used to match the assumed .FASTA extension for the rest of the workflow. The type strain of Salmonella enterica was downloaded and used in CheckM's workflow.

Results from this step will be output to checkm_results within the specified output directory in a file called "checkm_quality.tsv".
