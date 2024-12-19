Workflow-of-Nextflow

Data Cleaning and Assembly Workflow

This workflow script combines individual scripts developed by team members to perform the following tasks: assessing read quality, trimming reads, removing phiX contamination, assessing post-trimming quality, and assembling samples. The script operates on a set of input FASTQ files.

Prerequisites

You must have a conda environment with the following dependencies installed:

Python 3.8

FastQC

MultiQC

Trimmomatic

BBMap

SKESA

Biopython (version 1.75)

Additionally, you will need the filter.contigs.py script downloaded. Update the script paths to point to the file's storage location.

Workflow Steps

Run FastQC on raw FASTQ data.

Run MultiQC to summarize FastQC results.

Unzip compressed FASTQ files.

Trim reads with Trimmomatic.

Run FastQC on trimmed reads.

Run MultiQC to summarize FastQC results for trimmed reads.

Remove phiX contamination using BBMap.

Run FastQC on phiX-free reads.

Run MultiQC to summarize FastQC results for phiX-free reads.

Assemble cleaned reads using SKESA.

Filter assembled contigs using filter.contigs.py.

Notes

The script creates directories for organizing data:

unzip

trim_data

fastqc_results

trimmed_no_phiX

fastqc_noPhiX_results

SKESA_Assembled

SKESA_Filtered

Final cleaned and assembled reads are located in the SKESA_Filtered folder.

Instructions

Set Directories: Update the inputDir variable with the location of your FASTQ files.

Update Tool Paths: Verify paths for the tools (FASTQC, MULTIQC, TRIMMOMATIC, BBDUK_SCRIPT, SKESA, FILTER_SCRIPT).

Gene Prediction and Annotation

This pipeline, developed by Team D Group 2, processes assembly FASTA files to predict and annotate genes. The results are stored in a pipeline_output directory.

Prerequisites

Use the phase_2.yml environment file to create a conda environment with the necessary dependencies. The pipeline script requires the working directory to contain both the script and the data directory with FASTA assemblies.

Steps

Gene Prediction:

Use Prodigal for coding region prediction.

Use Barrnap for 16S rRNA region prediction.

Extract coding sequences using Bedtools.

Results are stored in pipeline_output/prediction_results.

Functional Annotation:

AMR Finder Plus: Identifies antibiotic resistance, virulence, and stress response genes.

Results: pipeline_output/amr_annotations.

Eggnog Mapper: Annotates coding regions using the Eggnog database.

Downloads and sets up the Eggnog database automatically.

Results: pipeline_output/FINAL_ANNOTATIONS.

Genotyping, Taxonomic Classification, and Quality Assessment

This pipeline, developed by Team D Group 3, performs genotyping, taxonomic classification, and quality assessment on assembly files.

Prerequisites

Clone the GitHub repository to your local machine.

Use the phase_3.yml environment file to create a conda environment.

Download the GTDB database (~84GB) and place it in the working directory as gtdbtk_data.

Steps

Genotyping with MLST:

Input: Assembly FASTA files.

Output: mlst_summary.tsv in the MLST_results directory.

Taxonomic Classification with GTDB-TK:

Uses the classify_wf workflow.

Results: gtdbtk.bac120.summary.tsv in gtdbk_results.

Quality Assessment with CheckM:

Evaluates genome completeness and contamination.

Results: checkm_quality.tsv in checkm_results.

Additional Tools and Steps

1. Panaroo: Pangenome Analysis

Run Prokka on assembly files to annotate them.

Run Panaroo on Prokka output files.

Visualize results using Cytoscape.

2. Sourmash: Metagenomic Analysis

Create and compare scaled signatures to identify contamination and strains.

3. kSNP: SNP Discovery

Prepare input files with MakeKSNP4infile.

Determine k-mer length using Kchooser4.

Run kSNP.

4. Bindash: Genome Comparison

Create sketches for assembly files.

Compare genomes using Jaccard similarity.
