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


