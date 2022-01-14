<div align="center">
    <h1>Clc Bio formatter</h1>
    <br />
</div>


## General information

* **Author(s):**            Alejandra Hernández Segura
* **Organization:**         National Institute for Public Health and the Environment (RIVM)
* **Department:**           Centre for Research Infectious Diseases Diagnostics and Screening (IDS), Bacteriology (BPD)
* **Start date:**           14 - 01 - 2022

## About this project

This is a small package/script to re-format the headers of fasta files to make them ready to import into CLC Bio. It is specifically made for the format desired by the AMR group of the IDS so the usage is very tailored to their needs. The final fasta header is as follows: "><sample_name>\_contig_<contig_number>_ Average coverage: <coverage_of_contig>"

## Prerequisities

In order to use this repo as a pipeline, it is necessary that you have: 

* **Linux + conda** A Linux-like environment where the command 'realpath' is installed (for instance, the Debian distribution or a normal linux distribution with this library added)
* **[Singularity](https://sylabs.io/guides/3.8/user-guide/)** installed and working. 
* Assumes that you are working on a cluster that accepts the `bsub` command

In order to use this repo as a python package, it is necessary that you have:
* Python >= 3.9

## Installation and usage

There are two ways to use this repository: as a pipeline or as a python package:

1. Use it as a pipeline:

Clone the repository:

```
git clone https://github.com/AleSR13/clcbioformatter.git
```
Alternatively, you can download it manually as a zip file (you will need to unzip it then). If you decide to download the zip only, the pipeline version will not be stored in the audit trail.  

**IMPORTANT NOTE**: You need to have [Singularity](https://sylabs.io/guides/3.8/user-guide/) and the pipeline assumes that you are in a cluster that accepts the `bsub` command. 

2. Use it as a python package:

```
pip install --editable git+https://github.com/AleSR13/clcbioformatter@master#egg=clcbioformatter
```


### The base command to run this program. 

However you decide to run the repo (package or pipeline), the input directory needs to have fasta files (<sample_name>.fasta) and a corresponding bbtools result file (<sample_name>_perMinLenFiltScaffolds.tsv). If there is no bbtools result file for each of the samples, the fasta files cannot be renamed.

1. Use it as a pipeline

To run it as a pipeline, your output directory must already exist. The command to run it is:

```
bash run_pipeline.sh <input_dir> <output_dir>
```
2. Use it as a python package

```
from clcbioformatter import multifile_formatter
multifile_formatter.reformat_directory(input_dir, output_dir, cores)
```

or 

```
from clcbioformatter import multifile_formatter
clcbioformatter.multifile_formatter.reformat_file_list(fasta_list, bbtools_list, output_dir, cores)
```

where fasta_list is a python list of the paths of the fasta files to rename and bbtools_list is a python list of the corresponding bbtools_results files (no need to be in order). Cores are the number of cores/threads that can be used. Default is to use as many cores as they are available.

## Issues  

* The pipeline currently only supports LSF clusters.
* Any issue can be reported in the [Issues section](https://github.com/AleSR13/clcbioformatter/issues) of this repository.

## License
This pipeline is licensed with an AGPL3 license. Detailed information can be found inside the 'LICENSE' file in this repository.

## Contact
* **Contact person:**       Alejandra Hernández Segura
* **Email**                 ale.hdz.segura@gmail.com