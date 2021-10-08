#!/bin/bash
dssource=ria+file:///cbica/projects/Shoreline/full_benchmark/shoreline-benchmark/input_ria#f8dbe3f8-b4d0-47ae-8b07-cb4e0a5f03b8
pushgitremote=/cbica/projects/Shoreline/full_benchmark/shoreline-benchmark/output_ria/f8d/be3f8-b4d0-47ae-8b07-cb4e0a5f03b8
PROJECTROOT=/cbica/projects/Shoreline/full_benchmark/shoreline-benchmark
LOGDIR=/cbica/projects/Shoreline/full_benchmark/shoreline-benchmark/analysis/logs
DSLOCKFILE=/cbica/projects/Shoreline/full_benchmark/shoreline-benchmark/analysis/.SGE_datalad_lock

# USAGE bash code/qsub_rerun.sh [do run]
# With no arguments, print whether the branch exists in
# the output_ria (the job has completed successfully)
#

QSIPREP_SCHEMES="ABCD DSIQ5 HCP HASC55"
EDDY_SCHEMES="ABCD HCP PNC"
NOISES="realistic"
PERCENT_MOTION=15
NUM_PERMS=10
#DENOISERS="dwidenoise none patch2self"
DENOISERS="dwidenoise"

getreq(){
    case $1 in

    HCP | DSIQ5)
        memreq="80G"
        threadreq="4-6"
        ;;
    ABCD)
        memreq="48G"
        threadreq="2-4"
        ;;
    PNC | HASC55)
        memreq="36G"
        threadreq="2-4"
        ;;
    *)
        memreq="54G"
        threadreq="2-4"
        ;;

    esac
}

dorun=0
if [ $# -gt 0 ]; then
    dorun=1
    echo Submitting jobs to SGE
fi

# Discover which branches have completed
cd ${PROJECTROOT}/output_ria/alias/data/
branches=$(git branch -a | grep job- | tr '\n' ' ' | sed 's/  */,/g')
running_branches=$(qstat -r | grep "Full jobname" | tr -s ' ' | cut -d ' ' -f 4 | tr '\n' ',')

submit_unfinished(){

    BRANCH="${method}-${scheme}-${noise}-${PERCENT_MOTION}-${transform}-${denoise}-${simnum}"
    branch_ok=$(echo $branches | grep "${BRANCH}," | wc -c)
    branch_submitted=$(echo $running_branches | grep "${BRANCH}," | wc -c)

    # check status of this branch
    if [ ${branch_ok} -gt 0 ]; then
        echo FINISHED: $BRANCH

    elif [ "${branch_submitted}" -gt 0  ]; then
        echo WAITING FOR: ${BRANCH}

    else
        echo INCOMPLETE: $BRANCH

        # Run it if we got an extra argument
        if [ ${dorun} -gt 0 ]; then

            # Set variables for resource requirements
            getreq

            # Do the qsub call
            set +x
            qsub \
                -e ${LOGDIR} -o ${LOGDIR} \
                -cwd \
                -l "h_vmem=${memreq}" \
                -pe threaded ${threadreq} \
                -N x${BRANCH} \
                -v DSLOCKFILE=$DSLOCKFILE \
                code/participant_job.sh \
                    ${dssource} \
                    ${pushgitremote} \
                    ${scheme} \
                    ${noise} \
                    ${PERCENT_MOTION} \
                    ${simnum} \
                    ${method} \
                    ${transform} \
                    ${denoise}
            set -x
        fi

    else

    fi
}

cd $PROJECTROOT/analysis
for denoise in ${DENOISERS}
do
    for noise in ${NOISES}
    do
        for simnum in `seq ${NUM_PERMS}`
        do
            method=3dSHORE
            for scheme in ${QSIPREP_SCHEMES}
            do
                transform=Rigid
                submit_unfinished

                transform=Affine
                submit_unfinished
            done

            method=eddy
            for scheme in ${EDDY_SCHEMES}
            do
                # One for linear
                transform=Linear
                submit_unfinished

                # One for quadratic
                transform=Quadratic
                submit_unfinished
            done
        done
    done
done

