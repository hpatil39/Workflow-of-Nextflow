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


Genotyping, Taxonomic Classification, and Quality Assessment - D3
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
