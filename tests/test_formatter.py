import pytest
from clcbioformatter.reformat_fastaheader import reformat_fasta
from clcbioformatter.multifile_formatter import reformat_directory
import pathlib

############# Fixtures #####################

@pytest.fixture(scope='function')
def input_dir() -> pathlib.Path:
    input_dir = pathlib.Path('tests/test_data')
    return input_dir

@pytest.fixture(scope='function')
def output_dir() -> pathlib.Path:
    output_dir = pathlib.Path('tests/test_output')
    output_dir.mkdir(exist_ok=True)
    yield output_dir
    for file_ in output_dir.glob('*'):
        file_.unlink()
    output_dir.rmdir()

@pytest.fixture(scope='function')
def input_singlefile(input_dir) -> pathlib.Path:
    input_singlefile = {}
    input_singlefile['fasta_file'] = input_dir.joinpath('sample1.fasta')
    input_singlefile['pileup_result_file'] = input_dir.joinpath('sample1_perMinLenFiltScaffold.tsv')
    return input_singlefile


############### Tests ######################

def test_singlefileformatting(input_singlefile, output_dir):
    reformat_fasta(
        **input_singlefile, output_dir = output_dir
    )
    assert output_dir.exists()
    expected_output_file = output_dir.joinpath('sample1.fasta')
    assert expected_output_file.exists()
    with open(expected_output_file) as f:
        firstline = f.readline().rstrip()
        assert str(firstline).startswith('>sample1_contig_1 Average coverage: 150.12')

def test_dirformatting(input_dir, output_dir):
    reformat_directory(
        input_dir, output_dir, 1
    )
    assert output_dir.exists()
    expected_output_file1 = output_dir.joinpath('sample1.fasta')
    expected_output_file2 = output_dir.joinpath('sample2.fasta')
    assert expected_output_file1.exists()
    assert expected_output_file2.exists()
    with open(expected_output_file1) as f:
        firstline = f.readline().rstrip()
        assert firstline.startswith('>sample1_contig_1 Average coverage: 150.12')
    with open(expected_output_file2) as f:
        firstline = f.readline().rstrip()
        assert firstline.startswith('>sample2_contig_1 Average coverage: 2.11')