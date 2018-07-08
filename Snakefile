import pandas as pd
from snakemake.utils import validate, min_version
##### set minimum snakemake version #####
min_version("5.1.2")

##### load config and sample sheets #####

configfile: "config.yaml"

samples = pd.read_table(config["samples"], index_col="sample")
units = pd.read_table(config["units"], index_col=["sample", "unit"], dtype=str)
units.index = units.index.set_levels([i.astype(str) for i in units.index.levels]) # enforce str in index


##### target rules #####

rule all:
    input:
        "qc/multiqc.html",
        expand("reads/trimmed/{unit.sample}-{unit.unit}-R{read}-trimmed.fq.gz",
               unit=units.reset_index().itertuples(),
               read=[1, 2]),
        expand("reads/aligned/{unit.sample}-{unit.unit}_fixmate.cram",
               unit=units.reset_index().itertuples())


##### setup singularity #####

# this container defines the underlying OS for each job when using the workflow
# with --use-conda --use-singularity
singularity: "docker://continuumio/miniconda3:4.4.10"


##### load rules #####

include_prefix="rules"

include:
    include_prefix + "/functions.py"
include:
    include_prefix + "/qc.smk"
include:
    include_prefix + "/trimming.smk"
include:
    include_prefix + "/alignment.smk"
