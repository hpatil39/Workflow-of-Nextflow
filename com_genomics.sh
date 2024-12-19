# Comparative_Genomics
The following pipeline was designed by Team D Group 4.

### Step 1: panaroo 

Here, we demonstrate how to use panaroo:

##### Running panaroo
Running MLST is simple and MLST can be run on all .fasta or .fna files in a directory at once. All of our files were .fasta files. We chose to redirect MLST output to a tsv file. 
```
# loop through assembly files 
for file in ~/input_data/*; do   #input_data is where the final fasta file of group A is located
    if [ -f "$file" ]; then
        filename=$(basename -- "$file")
        filename_no_ext="${filename%.*}"

        # run Prokka
        prokka "$file" --outdir "~/panaroo_output_dir/$filename_no_ext" --prefix "$filename_no_ext"#panaroo_output_dir is where you want to output your panaroo result
    fi
done


mkdir -p ~/panaroo_prokka # collect all .gff files

mkdir -p ~/paranoo_gff_dir # output for gff files

# find all gffs in subfolders and copy them to specified dir
find ~/panaroo_prokka -mindepth 2 -type f -name "*.gff" -exec cp {} ~/paranoo_gff_dir \;

# run panaroo
panaroo -i ~/gff_dir/*.gff -o ./results/ --clean-mode strict -f 0.5

# view graphs with Cytoscape application 

```

### Step 2: sour mash 

Here, we demonstrate how to use sour mash:

##### install sour mash
```
conda create -y -n smash sourmash-minimal
conda activate smash
sourmash --version

```

##### generate scaled signature from our refrenece
```
sourmash sketch dna -p k=31 reference.fna -o ecoli-reads.sig

```

##### generate scaled signature from our genome
```
mkdir sour_mash_output

for file in ~/input_data/*; do
    filename=$(basename "$file" .fastq.gz)
    sourmash sketch dna -p k=31 "$file" -o "~/sour_mash_output/${filename}.sig"
done

sourmash index ~/sour_mash_output/*.sig

```
##### Compare for contamination
```
msourmash search ~/ecoli-reads.sig ~/sour_mash_output/D0344683_R1.sig.sbt.zip 

sourmash compare ~/sour_mash_output/*.sig -o ecoli_cmp

sourmash plot --pdf --labels ecoli_cmp

```
##### What's in my metagenome
##### curl -L -o genbank-k31.lca.json.gz https://osf.io/4f8n3/download

#####This will get the type of strain
#####sourmash gather /Users/nanditapuri/Desktop/Georgia_Tech/Computational_Genomics/Group_Project/sour_mash/sigs/D0344683_R1.sig.sbt.zip /Users/nanditapuri/Desktop/Georgia_Tech/Computational_Genomics/Group_Project/sour_mash/genbank-k31.lca.json.gz

### Step 3: ksnp 

Here, we demonstrate how to use ksnp:

##### install kSNP4.1 and follow user guide instructions to download and run

##### make in file for kSNP
```
# directory where your assemblies or raw files are located
cd ~/input_data #directory where your assemblies or raw files are located
MakeKSNP4infile –indir ~/input_data –outfile in_file S

```
##### determine optional k-mer length for analysis
```
Kchooser4 –in in_file 
```
##### run kSNP4.1
```
kSNP4 -in in_file -k 17 –NJ –ML -outdir Run1 
```

### Step 4: bindash 

Here, we demonstrate how to use bindash:
##### install bindash
```
git clone https://github.com/jianshu93/bindash.git
cd bindash
CC=gcc-13 CXX=g++-13 cmake .
make

```
##### make assembled files provided by group 1 .fnas
```
cd ~/input_data
for file in *; do
    if [ -f "$file" ]; then
        mv "$file" "${file}.fna"
    fi
done
```
##### create list of assembly files
```
cd ~/input_data
setopt null_glob
assemblies=( *.fna )
unsetopt null_glob
```
##### run bindash
```
export PATH=/Users/savannahlinen/bindash/build/bindash:$PATH
for assembly in ～/input_data/*.fna; do
  bindash sketch --kmerlen=21 --sketchsize64=5000 --bbits=64 --outfname="${assembly}.sketch" ${assembly}
done


# Iterate over each assembly file in the input_data directory
find input_data -type f -name '*.fna' | while read -r assembly; do
  # Get the basename of the assembly file without the extension
  sampleA=$(basename "$assembly" .fna)
  
  # Compare the current assembly file with all other assembly files in the input_data directory
  find input_data -type f -name '*.fna' | while read -r other_assembly; do
    if [ "$assembly" != "$other_assembly" ]; then
      sampleB=$(basename "$other_assembly" .fna)
      
      # Run bindash command to compare the current assembly with the other assembly
      bindash dist "$assembly".sketch "$other_assembly".sketch > "bindash_output/${sampleA}_${sampleB}.tsv"
    fi
  done
done
```
##### view output in tsv & save to .tsv file
```
cat ~/bindash_output/*.tsv | awk '{print $1 "\t" $2 "\t" $5}' > bindash_output.tsv
```
##### analysis of values to identify outliers
```
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

df = pd.read_csv('bindash_output.tsv', sep='\t') #read in .tsv

# identify numerator & denominator values of Jaccard Index, calculate percentage overlap
numerator_values = df.iloc[:, 2].apply(lambda x: float(x.split('/')[0]))
denominator_values = df.iloc[:, 2].apply(lambda x: float(x.split('/')[1]))
percentage_values = (numerator_values / denominator_values) * 100  

# calculate general statistics 
mean = np.mean(percentage_values)
std_dev = np.std(percentage_values)
q1 = np.percentile(percentage_values, 25)
q3 = np.percentile(percentage_values, 75)
iqr = q3 - q1
min_value = np.min(percentage_values)
max_value = np.max(percentage_values)


# Identify outliers
outliers = df[(percentage_values < 25)]
outlier_files = outliers.iloc[:, 1].map(lambda x: os.path.basename(x))

# plot box plot 
plt.figure(figsize=(8, 6))
plt.boxplot(percentage_values)
plt.title('Boxplot of Jaccard Index between Q and T')
plt.ylabel('Jaccard Index (%)')
plt.show()

# print stats 
print("Mean:", mean)
print("Standard Deviation:", std_dev)
print("Q1:", q1)
print("Q3:", q3)
print("IQR:", iqr)
print("Min:", min_value)
print("Max:", max_value)
print("Outliers:")
print(outlier_files)
```




