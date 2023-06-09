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

DIR="$(dirname ${BASH_SOURCE[0]} )"
cd ${DIR}

if [ ! -d "${INPUTDIR}" ] || [ ! -d "${OUTPUTDIR}" ]
then
  echo "Either the input directory (${INPUTDIR}) or the output directory (${OUTPUTDIR}) do not exist!"
  exit 1
fi

#----------------------------------------------#
## make sure conda works

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/mnt/miniconda/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/mnt/miniconda/etc/profile.d/conda.sh" ]; then
        . "/mnt/miniconda/etc/profile.d/conda.sh"
    else
        export PATH="/mnt/miniconda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<export -f conda
export -f __conda_activate
export -f __conda_reactivate
export -f __conda_hashr


#----------------------------------------------#
# Create the environment

# we can use the base installation of mamba to create the environment. 
# Swapping to a parent env is not necessary anymore.
mamba env create -f envs/master_env.yaml --name pipeline_env
conda activate pipeline_env

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

# sing_image="/mnt/db/juno/sing_containers/clcbioformatter_v0.1.img"
# if [ ! -f ${sing_image} ]
# then
#   singularity pull --name "${sing_image}" library://alesr13/default/clcbioformatter:sha256.3cf5a626bad956d5bc9e35cadd71ea4d5f509007002429e24ad887e9e5dd1dc0
# fi

log_dir="${OUTPUTDIR}/log"
mkdir -p "${log_dir}"
reformatted_dir="${OUTPUTDIR}/reformatted_fasta"
mkdir -p "${reformatted_dir}"

bsub_command=" bsub -q ${QUEUE} \
                -n {threads} \
                -o ${log_dir}/clcbioformatter_bsub.out \
                -e ${log_dir}/clcbioformatter_bsub.err \
                -R \"span[hosts=1]\" \
                -R \"rusage[mem={resources.mem_gb}G]\" \
                -M {resources.mem_gb}G \
                -W 60 "

singularity_args=" --bind ${INPUTDIR}:${INPUTDIR} \
        --bind ${OUTPUTDIR}:${OUTPUTDIR} \
        --bind $(dirname ${BASH_SOURCE[0]}):/home/${USER}/ "

snakemake --cores 250 \
    --jobs 99 \
    --config "input_dir"="${INPUTDIR}" "reformatted_dir"="${reformatted_dir}" "log_dir"="${log_dir}" \
    --jobname "clcbioformatter_{jobid}" \
    --use-singularity \
    --singularity-args "${singularity_args}" \
    --singularity-prefix '/mnt/db/juno/sing_containers/'\
    --keep-going \
    --printshellcmds \
    --latency-wait 60 \
    --cluster "${bsub_command}"

result="$?"

# Propagate metadata

set +euo pipefail

SEQ_KEYS=
SEQ_ENV=$(env | grep irods_input_sequencing)
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

version=$(git --git-dir .git log -n 1 --pretty=format:"%H")

echo "clcbioformatter_version: '${version}'" >> "${OUTPUTDIR}/metadata.yml"

if [ ${result} == 0 ]
then
  # I don know why but a file '0' is made when the job is successful
  rm -f 0
  echo -e "\n\nFinished successfully reformatting the fasta files from ${INPUTDIR}."
  echo -e "\nThe re-formatted files can be found at ${reformatted_dir}.\n"
else
  echo -e "\nAn error occured while running the clcbioformatter! Please refer to the log files in ${log_dir}\n"
fi

exit "${result}"
