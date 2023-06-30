#!/usr/bin/env python
# -*- coding: utf-8 -*-

import io
import os
# import sys
# from shutil import rmtree

from setuptools import find_packages, setup, Command

NAME = 'clcbioformatter'
DESCRIPTION = 'Package to add headers to a fasta file to make them compatible with CLC Bio.'
URL = 'https://github.com/AleSR13/clcbioformatter'
EMAIL = 'ale.hdz.segura@gmail.com'
AUTHOR = 'Alejandra Hernández Segura'
REQUIRES_PYTHON = '>=3.9'
VERSION = '0.1.7'


REQUIRED = [
    # 'requests', 'maya', 'records',
]


EXTRAS = {
    # 'fancy feature': ['django'],
}


EXCLUDE = [
    "test", "*.test", "*.test.*", "test.*"
]


here = os.path.abspath(os.path.dirname(__file__))

# Import the README and use it as the long-description.
try:
    with io.open(os.path.join(here, 'README.md'), encoding='utf-8') as f:
        long_description = '\n' + f.read()
except FileNotFoundError:
    long_description = DESCRIPTION

# Load the package's __version__.py module as a dictionary.
about = {}
if not VERSION:
    project_slug = NAME.lower().replace("-", "_").replace(" ", "_")
    with open(os.path.join(here, project_slug, '__version__.py')) as f:
        exec(f.read(), about)
else:
    about['__version__'] = VERSION


setup(
    name=NAME,
    version=about['__version__'],
    description=DESCRIPTION,
    long_description=long_description,
    long_description_content_type='text/markdown',
    author=AUTHOR,
    author_email=EMAIL,
    python_requires=REQUIRES_PYTHON,
    url=URL,
    packages=find_packages(exclude=["tests", "*.tests", "*.tests.*", "tests.*"]),
    install_requires=REQUIRED,
    extras_require=EXTRAS,
    include_package_data=True,
    license='AGPL3',
    classifiers=[
        # Full list: https://pypi.python.org/pypi?%3Aaction=list_classifiers
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: Implementation :: CPython',
        'Natural Language :: English',
        'Topic :: Scientific/Engineering :: Bio-Informatics'
    ],
)