import pathlib

#################################################################################
#####                Define input and output directory                      #####
#################################################################################

input_dir = pathlib.Path(config['input_dir'])
reformatted_dir = pathlib.Path(config['reformatted_dir'])
log_dir = pathlib.Path(config['log_dir'])
sing_image = pathlib.Path('/mnt/db/juno/sing_containers/clcbioformatter_v0.1.img')

samples=[fasta_file.stem for fasta_file in input_dir.joinpath('de_novo_assembly_filtered').glob('*.fasta')]

#@################################################################################
#@####                                Rule                                   #####
#@################################################################################

localrules:
    all

rule all:
    input:
        expand(reformatted_dir.joinpath('{sample}.fasta'), sample=samples)

rule clcbioformatter:
    input:
        fasta = lambda wildcards: input_dir.joinpath('de_novo_assembly_filtered', f'{wildcards.sample}.fasta'),
        pileup = lambda wildcards: input_dir.joinpath('qc_de_novo_assembly', 'bbtools_scaffolds', 'per_sample', f'{wildcards.sample}_perMinLenFiltScaffold.tsv')
    output: str(reformatted_dir) + '/{sample}.fasta'
    message: 'Re-formatting {wildcards.sample}...'
    container: 'docker://python:3.9'
    # container: 'library://alesr13/clcbioformatter/clcbioformatter.sif:v0.1.1'
    threads: 1
    resources: mem_gb=10
    log: str(log_dir) + '/clcbioformatter_{sample}.log'
    shell:
        'python clcbioformatter/reformat_fastaheader.py -f {input.fasta} -p {input.pileup} -o $(dirname {output}) > {log}'

#@################################################################################
#@####              Finalize pipeline (error/success)                        #####
#@################################################################################

onerror:
    shell("""
echo -e "Something went wrong with the clcbioformatter. Please check the log files in {reformatted_dir}/log/"
    """)


