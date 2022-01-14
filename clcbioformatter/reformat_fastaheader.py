import argparse
import pathlib
import subprocess

def sample_name_from_file_path(file_path: str):
    file_path = pathlib.Path(file_path)
    sample_name = file_path.stem.replace('_perMinLenFiltScaffold', '')
    return sample_name

def round_coverage(coverage: str):
    coverage_num = float(coverage)
    return f' Average coverage: {round(coverage_num, 2)}'

def extract_info_row_pileup_result(row):
    content_row = str(row, 'UTF-8').split('\t')
    scaffold_old_name = content_row[0]
    scaffold_coverage = round_coverage(content_row[1])
    return scaffold_old_name, scaffold_coverage

def reformat_fastaheader(old_header, new_header, file_path):
    try:
        subprocess.check_output(
            f'grep -c "{old_header}" {file_path}',
            stderr=subprocess.STDOUT,
            shell=True
        )
        subprocess.check_output(
            f"sed -i 's/>{old_header}/>{new_header}/g' {file_path}",
            stderr=subprocess.STDOUT,
            shell=True
        )
        print(f'{old_header} renamed to {new_header}')
    except:
        print(f'The contig {old_header} could not be renamed. See log files to find the issue.')

def make_copy_of_file(file_, output_dir):
    file_name = pathlib.Path(file_).name
    new_file = pathlib.Path(output_dir).joinpath(file_name)
    subprocess.check_output(
        f'cp "{file_}" {new_file}',
        stderr=subprocess.STDOUT,
        shell=True
    )
    return new_file

def reformat_fasta(pileup_result_file: str, fasta_file: str, output_dir: str = None):
    sample_name = sample_name_from_file_path(pileup_result_file)
    if output_dir is not None:
        fasta_file = make_copy_of_file(file_=fasta_file, output_dir=output_dir)
    contig_number = 0
    with open (pileup_result_file, 'rb') as file_:
        for row in file_:
            if contig_number >0:
                contig_name = 'contig_' + str(contig_number)
                old_header, coverage = extract_info_row_pileup_result(row)
                new_header = sample_name + '_' + contig_name + coverage
                reformat_fastaheader(old_header, new_header, fasta_file)
            contig_number += 1

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description = "Reformat the header of fasta files to make them compliant with CLC bio."
    )
    parser.add_argument(
        "-p",
        "--pileup_res",
        type = pathlib.Path,
        metavar = "FILE",
        help = "Relative or absolute path to the results from pileup <sample>_perMinLenFiltScaffold.tsv."
    )
    parser.add_argument(
        "-f",
        "--fasta",
        type = pathlib.Path,
        metavar = "FILE",
        help = "Fasta file from which the headers will be renamed."
    )
    args = parser.parse_args()
    reformat_fasta(args.pileup_res, args.fasta)
