#!/bin/bash

# Wrapper for clcbioformatter

set -euo pipefail

#----------------------------------------------#
# User parameters
input_dir="${1%/}"
output_dir="${2%/}"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"
cd ${DIR}

# Sanity checks
if [ ! -z "${1}" ] || [ ! -z "${2}" ]
then
  INPUTDIR=$(realpath ${1})
  OUTPUTDIR=$(realpath ${2})
else
  echo "Not enough arguments were provided. This script needs 2 arguments: input directory and output directory."
  exit 1
fi

if [ ! -d "${INPUTDIR}" ] || [ ! -d "${OUTPUTDIR}" ]
then
  echo "Either the input directory (${INPUTDIR}) or the output directory (${OUTPUTDIR}) do not exist!"
  exit 1
fi

#----------------------------------------------#
# Create/update necessary environments
# PATH_MASTER_YAML="clcbioformatter.yaml"
# MASTER_NAME=$(head -n 1 ${PATH_MASTER_YAML} | cut -f2 -d ' ')

echo -e "\nUpdating necessary environments to run the pipeline..."

#----------------------------------------------#
# Run the pipeline

echo -e "\nRun pipeline..."

set +euo pipefail
if [ ! -z ${irods_runsheet_sys__runsheet__lsf_queue} ]; then
    QUEUE="${irods_runsheet_sys__runsheet__lsf_queue}"
else
    QUEUE="bio"
fi
set -euo pipefail

# Setting up the tmpdir for singularity as the current directory (default is /tmp but it gets full easily)
# Containers will use it for storing tmp files when building a container
export SINGULARITY_TMPDIR="$(pwd)"

sing_image="/mnt/db/juno/sing_containers/clcbioformatter_v0.1.img"
if [ ! -f ${sing_image} ]
then
  singularity pull --name "${sing_image}" library://alesr13/default/clcbioformatter:sha256.3cf5a626bad956d5bc9e35cadd71ea4d5f509007002429e24ad887e9e5dd1dc0
fi
singularity exec \
  --bind ${INPUTDIR}:${INPUTDIR} \
  --bind ${OUTPUTDIR}:${OUTPUTDIR} \
  $"${sing_image}" \
  python clcbioformatter/multifile_formatter.py -i ${INPUTDIR} -o ${OUTPUTDIR} -n 4
    
result=$?

# Propagate metadata

set +euo pipefail

SEQ_KEYS=
SEQ_ENV=`env | grep irods_input_sequencing`
for SEQ_AVU in ${SEQ_ENV}
do
    SEQ_KEYS="${SEQ_KEYS} ${SEQ_AVU%%=*}"
done

for key in $SEQ_KEYS irods_input_illumina__Flowcell irods_input_illumina__Instrument \
    irods_input_illumina__Date irods_input_illumina__Run_number irods_input_illumina__Run_Id
do
    if [ ! -z ${!key} ] ; then
        attrname=${key:12}
        attrname=${attrname/__/::}
        echo "${attrname}: '${!key}'" >> ${OUTPUTDIR}/metadata.yml
    fi
done

version=$(git rev-parse HEAD)
echo "clcbioformatter_version: '${version}'" >> ${OUTPUTDIR}/metadata.yml

if [ ${result} == 0 ]
then
  echo -e "\n\nFinished successfully reformatting the fasta files from ${INPUTDIR}."
  echo -e "\nThe re-formatted files can be found at ${OUTPUTDIR}.\n"
fi

exit ${result}
