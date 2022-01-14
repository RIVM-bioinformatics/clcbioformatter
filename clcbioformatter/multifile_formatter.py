import argparse
# from operator import add
from clcbioformatter.reformat_fastaheader import reformat_fasta
import pathlib
import warnings
import multiprocessing as mp


def make_file_dict(list_fasta: list, list_bbtools_res: list):
    '''Makes a dictionary with sample names as keys and with a 
    subdictionary with the 'fasta' and 'bbtools' files per sample.

    {sample1: 
        { fasta:sample1.fasta, 
        bbtools: sample1_perMinLenFiltScaffold.tsv },
    sample2: 
        { fasta:sample2.fasta, 
        bbtools: sample2_perMinLenFiltScaffold.tsv } 
    }

    Note that the stem of the files (without suffix) are expected to 
    be the sample name.
    '''
    file_dict = {pathlib.Path(file_path).stem: {'fasta': file_path} for file_path in list_fasta}
    bbtools_dict = {pathlib.Path(file_path).stem.replace('_perMinLenFiltScaffold', ''): file_path for file_path in list_bbtools_res}
    samples_without_bbtools_res = []
    for sample in file_dict:
        try:
            file_dict[sample]['bbtools'] = bbtools_dict[sample]
        except KeyError:
            samples_without_bbtools_res.append(sample)
    if len(samples_without_bbtools_res) > 0:
        warnings.warn(
            'These samples did not have a result for the bbtools '
            'contig metrics calculation (<sample_name>_perMinLenFiltScaffold.tsv) '
            'and therefore could not be reformatted: '
            f'{", ".join(samples_without_bbtools_res)}',
            category=UserWarning
        )
        [file_dict.pop(unpaired_sample) for unpaired_sample in samples_without_bbtools_res]
    return file_dict

def reformat_multiple_files(file_dict: dict, output_dir: str, cores: int):
    '''Function to apply the reformat_fasta() function to multiple 
    files
    '''
    pool = mp.Pool(cores)
    for sample in file_dict:
        pool.apply_async(
            reformat_fasta,
            args=(
                file_dict[sample]['bbtools'], 
                file_dict[sample]['fasta'],
                output_dir
            )
        )
    pool.close()
    pool.join()

def make_output_dir(output_dir: str):
    '''Function to make the output directory if one is given'''
    if output_dir is not None:
        pathlib.Path(output_dir).mkdir(parents=True, exist_ok=True)


def reformat_file_list(fasta_list: list, bbtools_list: list, output_dir: str, cores: int):
    '''Function to reformat a bunch of fasta_files given as a list and 
    their corresponding bbtools results given as a separate list.
    An output directory may be given. In that case, first a copy of the
    fasta file will be made and this copy will be adjusted to have the
    new fasta header'''
    file_dict = make_file_dict(
        list_fasta=fasta_list, 
        list_bbtools_res=bbtools_list
    )
    make_output_dir(output_dir)
    reformat_multiple_files(file_dict, output_dir, cores)

def reformat_directory(input_dir: str, output_dir: str, cores: int):
    '''Function to reformat any fasta file found in the input directory.
    It first searches (recursively) for fasta files and renames only 
    the ones that have a bbtools result file with the same sample name.'''
    input_dir = pathlib.Path(input_dir)
    output_dir = pathlib.Path(output_dir)
    fasta_files = [fasta_file for fasta_file in input_dir.glob('**/*.fasta')]
    bbtools_files = [fasta_file for fasta_file in input_dir.glob('**/*_perMinLenFiltScaffold.tsv')]
    reformat_file_list(fasta_list=fasta_files, bbtools_list=bbtools_files, output_dir=output_dir, cores=cores)


def main(input_dir, output_dir, fasta_files, bbtools_files, cores):
    if input_dir is not None:
        reformat_directory(input_dir, output_dir, cores)
    else:
        reformat_file_list(
            fasta_list=fasta_files, 
            bbtools_list=bbtools_files, 
            output_dir=output_dir,
            cores=cores
        )
        
if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Reformat multiple fasta files to make the header compatible with CLC bio.',
    )
    parser.add_argument(
        '-i', '--input_dir', 
        type=str, 
        default=None,
        metavar='DIR', 
        help='Input directory where the fasta files and bbtools results (<sample_name>_perMinLenFiltScaffold.tsv) reside.'
    )
    parser.add_argument(
        '-o', '--output_dir', 
        type=str, 
        default=None,
        metavar='DIR', 
        help='Output directory where to store the reformatted fasta files.'
    )
    parser.add_argument(
        '-f', '--fasta_files', 
        type=str, 
        default=[],
        metavar='PATHS', 
        help='Paths of multiple fasta files that want to be re-formatted.'
    )
    parser.add_argument(
        '-b', '--bbtools_files', 
        type=str, 
        default=[],
        metavar='PATHS', 
        help='Paths of multiple bbtools results files (<sample_name>_perMinLenFiltScaffold.tsv) corresponding to the fasta files that want to be re-formatted.'
    )
    parser.add_argument(
        '-n', '--cores', 
        type=int, 
        default=mp.cpu_count(),
        metavar='INT', 
        help='Number of cores to use.'
    )
    args = parser.parse_args()
    main(
        input_dir=args.input_dir,
        output_dir=args.output_dir,
        fasta_files=args.fasta_files,
        bbtools_files=args.bbtools_files,
        cores=args.cores
    )