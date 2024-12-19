import os
import subprocess
import glob
from pathlib import Path
from Bio.SeqUtils import GC

#must have conda environment with python=3.8 bioconda fastqc multiqc trimmomatic bbmap skesa and biopython (version 1.75) 

# ensure all directories are made prior to running this 
# Set input and output directories - MUST CHANGE TO MATCH WHERE YOUR DATA IS 
inputDir = '/Users/savannahlinen/Desktop/OneDrive_GT/BIOL_7210_TEAM_D/Data'

# Set paths to tools
FASTQC = 'fastqc'
MULTIQC = 'multiqc'
TRIMMOMATIC = 'trimmomatic'
BBDUK_SCRIPT = '/Users/savannahlinen/Desktop/OneDrive_GT/BIOL_7210_TEAM_D/trimmed/bbmap/bbduk.sh'
SKESA = 'skesa'
FILTER_SCRIPT = '/Users/savannahlinen/Desktop/OneDrive_GT/BIOL_7210_TEAM_D/filter.contigs.py'
PHIX_REF = '/Users/savannahlinen/Desktop/OneDrive_GT/BIOL_7210_TEAM_D/trimmed/phiX174_genome.fasta'

# Change directory, run FastQC on all files
os.chdir(inputDir)
fastq_files = glob.glob('*.fastq.gz')
# subprocess.run([FASTQC, '*.fastq.gz'])
for fastq_file in fastq_files:
    subprocess.run([FASTQC, fastq_file])

# MultiQC
subprocess.run([MULTIQC, '.'])

# Unzip 
zip_files = [f for f in os.listdir('.') if f.endswith('.gz')]
unzip_dir = 'unzip'
os.makedirs(unzip_dir, exist_ok=True)

for zip_file in zip_files:
    output_path = os.path.join(unzip_dir, os.path.splitext(os.path.basename(zip_file))[0])
    unzip_cmd = ['gunzip', '-c', zip_file]
    with open(output_path, 'wb') as out:
        subprocess.call(unzip_cmd, stdout=out)

print("Unzip complete!")

# Trimming
out_dir = 'trim_data'
os.makedirs(out_dir, exist_ok=True)

for filename in os.listdir(unzip_dir):
    if filename.endswith(".fastq"):
        input_file = os.path.join(unzip_dir, filename)
        output_file = os.path.join(out_dir, filename)
        
        # Call Trimmomatic
        trim_cmd = [TRIMMOMATIC, 'SE', '-phred33', input_file, output_file, 'ILLUMINACLIP:adapters.fa:2:30:10',
                    'LEADING:3', 'TRAILING:3', 'SLIDINGWINDOW:4:20', 'MINLEN:50']
        
        subprocess.call(trim_cmd)

print("Trimming complete!")

# FastQC for trimmed files
fastqc_outdir = 'fastqc_results'
os.makedirs(fastqc_outdir, exist_ok=True)

for filename in os.listdir(out_dir):
    if filename.endswith(".fastq"):
        input_path = os.path.join(out_dir, filename)
        output_path = os.path.join(fastqc_outdir, filename)
        
        fastqc_cmd = [FASTQC, input_path, "-o", fastqc_outdir]
        
        print("Running FastQC on", filename)
        subprocess.call(fastqc_cmd)

print("FastQC complete for all files!")

# Remove PhiX from trimmed files
noPhiXDir = 'trimmed_no_phiX'
os.makedirs(noPhiXDir, exist_ok=True)

for fastq_file in os.listdir(out_dir):
    if fastq_file.endswith(".fastq"):
        FILENAME = os.path.splitext(os.path.basename(fastq_file))[0]
        noPhiX_file = os.path.join(noPhiXDir, f'non_phix_{FILENAME}.fastq')

        subprocess.run([BBDUK_SCRIPT, 'in=' + os.path.join(out_dir, fastq_file),
                        'out=' + noPhiX_file, 'ref=' + PHIX_REF])

# FastQC on files with no PhiX
fastqc_noPhiX_dir = 'fastqc_noPhiX_results'
os.makedirs(fastqc_noPhiX_dir, exist_ok=True)

for noPhiX_file in os.listdir(noPhiXDir):
    if noPhiX_file.endswith(".fastq"):
        input_path = os.path.join(noPhiXDir, noPhiX_file)
        output_path = os.path.join(fastqc_noPhiX_dir, noPhiX_file)
        
        fastqc_cmd = [FASTQC, input_path, "-o", fastqc_noPhiX_dir]
        
        print("Running FastQC on", noPhiX_file)
        subprocess.call(fastqc_cmd)

print("FastQC complete for files with no PhiX!")


# Assemble with SKESA
skesaDir = 'SKESA_Assembled'
os.makedirs(skesaDir, exist_ok=True)

for fastq_file in os.listdir(noPhiXDir):
    if fastq_file.endswith(".fastq"):
        id = os.path.splitext(fastq_file)[0]  # Get the ID from the original filename
        skesa_output = os.path.join(skesaDir, f'{id}_skesa_assembled.fastq')
        
        subprocess.run([SKESA, '--reads', os.path.join(noPhiXDir, fastq_file),
                        '--contigs_out', skesa_output],
                       stdout=open(f'{skesaDir}/{id}_skesa.stdout.txt', 'w'),
                       stderr=open(f'{skesaDir}/{id}_skesa.stderr.txt', 'w'))

# Filter contigs
filteredDir = 'SKESA_Filtered'
os.makedirs(filteredDir, exist_ok=True)

for file in os.listdir(skesaDir):
    if file.endswith(".fastq"):
        id = file.split('_')[2]  # Extract ID from the filename
        base_name = os.path.splitext(file)[0]
        outfile = os.path.join(filteredDir, f'{id}_filtered')
        subprocess.run(['python', FILTER_SCRIPT, '-i', os.path.join(skesaDir, file),
                        '-o', outfile, '--len', '500', '--cov', '10'])


