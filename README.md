# Workflow-of-Nextflow

## Data Cleaning and Assembly Workflow
This pipeline processes input FASTQ files to clean, assemble, and organize data. It uses tools like FastQC, MultiQC, Trimmomatic, BBMap, and SKESA.

### Steps:
1. **Run FastQC** on raw reads.
2. **Summarize FastQC** with MultiQC.
3. **Trim reads** using Trimmomatic.
4. **Remove phiX contamination** with BBMap.
5. **Assemble reads** using SKESA.
6. **Filter contigs** with `filter.contigs.py`.

### Output:
Final cleaned and assembled FASTA files are stored in the `SKESA_Filtered` directory.

---

## Gene Prediction and Annotation
This pipeline predicts and annotates genes in assembly FASTA files using Prodigal, Barrnap, AMR Finder Plus, and Eggnog Mapper.

### Steps:
1. **Predict coding regions** with Prodigal and 16S regions with Barrnap.
2. **Annotate genes** with AMR Finder Plus and Eggnog Mapper.

### Output:
Annotated GFF3 files are located in the `FINAL_ANNOTATIONS` directory.

---

## Genotyping and Taxonomic Classification
This pipeline performs genotyping, taxonomic classification, and quality assessment using MLST, GTDB-TK, and CheckM.

### Steps:
1. **Genotyping:** MLST outputs `mlst_summary.tsv`.
2. **Taxonomic classification:** GTDB-TK outputs `gtdbtk.bac120.summary.tsv`.
3. **Quality assessment:** CheckM outputs `checkm_quality.tsv`.

---

## Pangenome and Metagenome Analysis
1. **Panaroo:** Annotate assemblies and visualize results in Cytoscape.
2. **Sourmash:** Identify contamination and strains.
3. **kSNP:** Perform SNP discovery.
4. **Bindash:** Compare genomes using Jaccard similarity.
