#!/bin/bash
set -e -u -x
sequence="$1"
noise="$2"
percent_motion="$3"
permutation_number="$4"
hmc_method="$5"
transform="$6"
denoise="$7"
motion_severity="$9"
outputname="$8"

CONTAINER=containers/images/bids/bids-qsiprep--0.14.3.sing
SOURCEBIND='-B /cbica/projects/Shoreline/code/qsiprep/qsiprep:/usr/local/miniconda/lib/python3.7/site-packages/qsiprep'

# Create the subset in bids_subset/
singularity exec --cleanenv -B ${PWD} \
    $CONTAINER python code/create_motion_subset.py \
        ${sequence} \
        ${noise} \
        ${percent_motion} \
        ${permutation_number} \
        ${motion_severity}


workdir=${PWD}/.git/tmp/wdir
mkdir -p ${workdir}

if [[ "${hmc_method}" == "eddy" ]];
then

    if [[ "${transform}" == "quadratic" ]];
    then
        singularity run --cleanenv -B ${PWD} \
            ${SOURCEBIND} \
            ${CONTAINER} \
            bids_subset \
            prep \
            participant \
            -v -v \
            -w ${workdir} \
            --n_cpus $NSLOTS \
            --stop-on-first-crash \
            --fs-license-file code/license.txt \
            --skip-bids-validation \
            --denoise-method ${denoise} \
            --eddy-config code/quadratic.json \
            --output-resolution 2.0
    else
        singularity run --cleanenv -B ${PWD} \
            ${SOURCEBIND} \
            ${CONTAINER} \
            bids_subset \
            prep \
            participant \
            -v -v \
            -w ${workdir} \
            --n_cpus $NSLOTS \
            --stop-on-first-crash \
            --fs-license-file code/license.txt \
            --skip-bids-validation \
            --denoise-method ${denoise} \
            --output-resolution 2.0
    fi

else
    # Run SHORELine
    singularity run --cleanenv -B ${PWD} \
        ${SOURCEBIND} \
        ${CONTAINER} \
        bids_subset \
        prep \
        participant \
        -v -v \
        -w ${workdir} \
        --n_cpus $NSLOTS \
        --stop-on-first-crash \
        --fs-license-file code/license.txt \
        --skip-bids-validation \
        --hmc-model 3dSHORE \
        --hmc_transform ${transform} \
        --shoreline-iters 2 \
        --b0-motion-corr-to first \
        --denoise-method ${denoise} \
        --output-resolution 2.0
fi

# Copy the ground-truth motion file into the results zip
cp bids_subset/sub-${sequence}/dwi/*_dwi_motion.txt prep/qsiprep/

cd prep
7z a ../${outputname} qsiprep
cd ..
rm -rf prep ${workdir}

