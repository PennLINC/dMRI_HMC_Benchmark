#!/usr/bin/env python
"""

USAGE:

python create_motion_subset.py sequence noise percent_motion permutation_number severity

Where
    sequence is HASC55, HCP, ABCD, PN, DSIQ5
    noise is "realistic" or "noisefree"
    percent_motion is 1-100
    permutation_number is an integer
    severity is "low" or "high"

Creates new version of the data with random volumes (determined by permutation_number)
are replaced with low|high motion versions of the same gradient direction. The percent
of volumes to be replaced is determined by percent_motion.
"""


import sys
import shutil
import os
import nibabel as nb
import numpy as np


def simulate_motion(
        seq='HASC55', noise='noisefree', percent_motion=10,
        permutation_number=999, severity=''):

    args = dict(seq=seq, noise=noise, percent_motion=percent_motion, severity=severity)

    dataset_description = \
        'inputs/data/{noise}/nomotion/' \
        'dataset_description.json'.format(**args)

    # No motion simulation
    nonmotion_dwi = \
        'inputs/data/{noise}/nomotion/sub-{seq}/' \
        'dwi/sub-{seq}_acq-{noise}Xnomotion_dwi.nii.gz'.format(**args)
    nonmotion_img = nb.load(nonmotion_dwi)
    nonmotion_data = nonmotion_img.get_fdata(dtype=np.float32)
    json = nonmotion_dwi[:-7] + '.json'
    bval = nonmotion_dwi[:-7] + '.bval'
    bvec = nonmotion_dwi[:-7] + '.bvec'

    # All motion simulation uses the low motion examples
    motion_file = 'inputs/data/ground_truth_motion/' \
        'sub-{seq}_acq-{noise}_run-{severity}motion_dwi_motion.txt'.format(**args)
    all_motion = np.loadtxt(motion_file)
    motion_dwi = \
        'inputs/data/{noise}/{severity}motion/sub-{seq}/' \
        'dwi/sub-{seq}_acq-{noise}X{severity}motion_dwi.nii.gz'.format(**args)
    motion_img = nb.load(motion_dwi)
    motion_data = motion_img.get_fdata(dtype=np.float32)

    out_dir = 'bids_subset/sub-{seq}/dwi'.format(**args)
    os.makedirs(out_dir, exist_ok=True)
    shutil.copyfile(dataset_description,
                    "bids_subset/dataset_description.json",
                    follow_symlinks=True)

    np.random.seed(permutation_number)
    args['permnum'] = permutation_number
    prefix = out_dir + '/sub-{seq}_acq-mot{percent_motion}perm' \
        '{permnum:03d}_dwi'.format(**args)
    shutil.copyfile(json, prefix + '.json', follow_symlinks=True)
    shutil.copyfile(bval, prefix + '.bval', follow_symlinks=True)
    shutil.copyfile(bvec, prefix + '.bvec', follow_symlinks=True)

    # Determine which volumes should get swapped with their motion version
    num_vols = nonmotion_img.shape[3]
    num_to_replace = int(num_vols * float(percent_motion) / 100)
    replace_vols = np.random.choice(num_vols - 1, size=num_to_replace,
                                    replace=False) + 1
    # create the new 4D image with the moved images mixed in
    nonmotion_data[..., replace_vols] = motion_data[..., replace_vols]
    nb.Nifti1Image(
        nonmotion_data, nonmotion_img.affine,
        nonmotion_img.header).to_filename(
            prefix + '.nii.gz')

    motion_params = np.zeros_like(all_motion)
    motion_params[replace_vols] = all_motion[replace_vols]
    np.savetxt(prefix + '_motion.txt', motion_params)


if __name__ == "__main__":
    sequence = sys.argv[1]
    noise = sys.argv[2]
    percent_motion = int(sys.argv[3])
    permutation_number = int(sys.argv[4])
    severity = sys.argv[5]
    simulate_motion(
        seq=sequence, noise=noise, percent_motion=percent_motion,
        permutation_number=permutation_number, severity=severity
    )

