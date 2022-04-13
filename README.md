# SHORELine and Eddy Benchmarking

## Dataset structure

- All inputs (i.e. building blocks from other sources) are located in
  `inputs/`.
- All custom code is located in `code/`.
- Results from running iterations are in `results`.

## Reproducing results

These workflows were run on the CUBIC HPC system at UPenn. The scripts and data
are organized to use the FAIRly BIG workflow, which submits many compute jobs
that write results to branches and at the very end merges the results into 
a single dataset with all the history contained.

You may not want to reproduce all the results (it will take a lot of computing resources),
but even if you want to look at the code and data you will first need to create a local
copy of the dataset

First, use `datalad` to get the data. 

 1. [Install datalad](http://handbook.datalad.org/en/latest/intro/installation.html) on a 
    Linux machine *with singularity version > 3 installed*.
 2. [Install datalad-osf](http://docs.datalad.org/projects/osf/en/latest/settingup.html#installation).
    This is likely just `pip install datalad-osf`.
 3. Clone this repository
```
$ datalad clone git@github.com:PennLINC/dMRI_HMC_Benchmark.git
$ cd dMRI_HMC_Benchmark
```

You can also see the history of every computation using `git log`. The most
recent commits are from merging results branches, which are not interesting.
But you can see the details from a specific commits, which can also be 
re-run on your machine.  For example, we know that the commit `7ca2bbbee5ae06f60737d2b798d962da65e352af`
ran SHORELine on an HCP sequence with 30% head motion volumes. We can
verify this with 

```
$ git show 7ca2bbbee5ae06f60737d2b798d962da65e352af

commit 7ca2bbbee5ae06f60737d2b798d962da65e352af
Author: Matt Cieslak <mattcieslak@gmail.com>
Date:   Mon Dec 6 06:24:12 2021 -0500

    [DATALAD RUNCMD] HCP realistic 30 24 3dSHORE Affine none high HCP_realistic_30_24_3dSHORE-Affine-none-high-qsiprep-0.14.3.zip

    === Do not change lines below ===
    {
     "chain": [],
     "cmd": "bash ./code/qsiprep_zip.sh HCP realistic 30 24 3dSHORE Affine none high HCP_realistic_30_24_3dSHORE-Affine-none-high-qsiprep-0.14.3.zip",
     "dsid": "f8dbe3f8-b4d0-47ae-8b07-cb4e0a5f03b8",
     "exit": 0,
     "extra_inputs": [],
     "inputs": [
      "inputs/data/realistic/highmotion/sub-HCP",
      "inputs/data/realistic/lowmotion/sub-HCP",
      "inputs/data/realistic/nomotion/sub-HCP",
      "inputs/data/realistic/nomotion/dataset_description.json",
      "inputs/data/ground_truth_motion",
      "containers/images/bids/bids-qsiprep--0.14.3.sing"
     ],
     "outputs": [
      "HCP_realistic_30_24_3dSHORE-Affine-none-high-qsiprep-0.14.3.zip"
     ],
     "pwd": "."
    }
    ^^^ Do not change lines above ^^^

diff --git a/HCP_realistic_30_24_3dSHORE-Affine-none-high-qsiprep-0.14.3.zip b/HCP_realistic_30_24_3dSHORE-Affine-none-high-qsiprep-0.14.3.zip
new file mode 120000
index 00000000..e261de7e
--- /dev/null
+++ b/HCP_realistic_30_24_3dSHORE-Affine-none-high-qsiprep-0.14.3.zip
@@ -0,0 +1 @@
+.git/annex/objects/XG/pX/MD5E-s1015209230--4a27c82ff56110fa6e2760bd1d88d52f.3.zip/MD5E-s1015209230--4a27c82ff56110fa6e2760bd1d88d52f.3.zip
```

which tells us that the command

```
$ bash ./code/qsiprep_zip.sh \
    HCP realistic 30 24 \
    3dSHORE Affine none high \
    HCP_realistic_30_24_3dSHORE-Affine-none-high-qsiprep-0.14.3.zip

```

was run and produced `HCP_realistic_30_24_3dSHORE-Affine-none-high-qsiprep-0.14.3.zip`.
All commands were run using the root of this repository as its working directory,
so this refers to the script `code/qsiprep_zip.sh` that you have in your clone.
If you'd like to run this simulation yourself you can simply run

```
$ datalad rerun 7ca2bbbee5ae06f60737d2b798d962da65e352af
```

and you will see that the input data as well as the QSIPrep container are 
downloaded and the command is rerun. This will take many hours and requires
a lot of memory (we suggest up to 24GB). 

If you'd like to get the data and container without rerunning anything, this
command will copy the data from OSF and singularityhub:

```
$ datalad get inputs/data containers
```

## How the simulation was run at UPenn

Although the individual workflows can be reproduced with `datalad rerun`,
we ran these workflows using our HPC's scheduling system. The job management
is in `code/qsub_rerun.sh`. You may need to adjust some of the hard-coded
paths in this script to match your local clone. 