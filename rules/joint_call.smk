

rule gatk_GenomicsDBImport:
    input:
        gvcfs=expand("variant_calling/{sample.sample}.{{interval}}.g.vcf.gz",
                     sample=samples.reset_index().itertuples())
    output:
        touch("db/imports/{interval}")
    # wildcard_constraints:
    #     chr="[0-9XYM]+"
    params:
        custom=java_params(tmp_dir=tmp_path(path=config.get("paths").get("to_tmp")), fraction_for=4),
        genome=resolve_single_filepath(*references_abs_path(), config.get("genome_fasta"))
    log:
        "logs/gatk/GenomicsDBImport/{interval}.info.log"
    benchmark:
        "benchmarks/gatk/GenomicsDBImport/{interval}.txt"
    run:
        gvcfs = _multi_flag("-V", input.gvcfs)
        shell(
            "mkdir -p db; "
            "gatk GenomicsDBImport --java-options {params.custom} "
            "{gvcfs} "
            "--genomicsdb-workspace-path db/{wildcards.interval} "
            "-L split/{wildcards.interval}-scattered.intervals "
            ">& {log} ")

rule gatk_GenotypeGVCFs:
    input:
        "db/imports/{interval}"
    output:
        protected("variant_calling/all.{interval}.vcf.gz")
    # wildcard_constraints:
    #     chr="[0-9XYM]+"
    conda:
       "../envs/gatk.yaml"
    params:
        custom=java_params(tmp_dir=tmp_path(path=config.get("paths").get("to_tmp")), fraction_for=4),
        genome=resolve_single_filepath(*references_abs_path(), config.get("genome_fasta"))
    log:
        "logs/gatk/GenotypeGVCFs/all.{interval}.info.log"
    benchmark:
        "benchmarks/gatk/GenotypeGVCFs/all.{interval}.txt"
    shell:
        "gatk GenotypeGVCFs --java-options {params.custom} "
        "-R {params.genome} "
        "-V gendb://db/{wildcards.interval} "
        "-O {output} "
        ">& {log} "