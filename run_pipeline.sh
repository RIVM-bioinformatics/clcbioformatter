#!/bin/bash

# Wrapper for clcbioformatter
set +x
set -euo pipefail

#----------------------------------------------#
# User parameters

# Sanity checks
set +euo pipefail
if [ ! -z "${1}" ] || [ ! -z "${2}" ]
then
  INPUTDIR=$(realpath ${1})
  OUTPUTDIR=$(realpath ${2})
else
  echo "Not enough arguments were provided. This script needs 2 arguments: input directory and output directory."
  exit 1
fi
set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null 2>&1 && pwd )"
cd ${DIR}

if [ ! -d "${INPUTDIR}" ] || [ ! -d "${OUTPUTDIR}" ]
then
  echo "Either the input directory (${INPUTDIR}) or the output directory (${OUTPUTDIR}) do not exist!"
  exit 1
fi

#----------------------------------------------#
# Run the pipeline

echo -e "\nRe-formatting  pipeline..."

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

# Generate random job_id
RANDOM=$(date +%s%N | cut -b10-19)
job_id="clcbioformatter_${RANDOM}"

log_dir="${OUTPUTDIR}/log"
mkdir -p "${log_dir}"
reformatted_dir=${OUTPUTDIR}/reformatted_fasta

echo -e "clcbioformatter job was submitted to the cluster with jobID: ${job_id}"

bsub -J "${job_id}" \
  -n 4 \
  -q "${QUEUE}" \
  -o "${log_dir}/clcbioformatter.out" \
  -e "${log_dir}/clcbioformatter.err" \
  -R \"span[hosts=1]\" \
  -W 60 \
  "singularity exec \
  --bind ${INPUTDIR}:${INPUTDIR} \
  --bind ${OUTPUTDIR}:${OUTPUTDIR} \
  --bind $(dirname "${BASH_SOURCE[0]}"):/home/${USER}/ \
  ${sing_image} \
  python clcbioformatter/multifile_formatter.py -i ${INPUTDIR} -o ${reformatted_dir} -n 4"

bwait -r 1 -w "ended(${job_id})"

# Sometimes bwait exits even if the output is not there so better to check the output dir is there:

if [ ! -d ${reformatted_dir} ]
then
  # Wait for results just in case
  sleep 100
fi
# If still the result is not there, fail
# Otherwise make sure that some files were produced
if [ ! -d ${reformatted_dir} ]
then
  result=1
else
  num_fasta_reformatted=$(find ${reformatted_dir} -type f -name *.fasta | wc -l)
  if [ ${num_fasta_reformatted} > 0 ]
  then
    result=0
  fi
fi

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

set -euo pipefail

version=$(git rev-parse HEAD)
echo "clcbioformatter_version: '${version}'" >> ${OUTPUTDIR}/metadata.yml

if [ ${result} == 0 ]
then
  # I don know why but a file '0' is made when the job is successful
  rm -f 0
  echo -e "\n\nFinished successfully reformatting the fasta files from ${INPUTDIR}."
  echo -e "\nThe re-formatted files can be found at ${OUTPUTDIR}.\n"
else
  echo -e "\nAn error occured while running the clcbioformatter! Please refer to the log files in ${log_dir}\n"
fi

exit ${result}
