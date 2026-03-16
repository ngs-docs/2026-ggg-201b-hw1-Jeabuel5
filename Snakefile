# (a) Dictionary mapping sample IDs to their download URLs
SAMPLES_MAP = {
    "ERR458496": "https://osf.io/tzagu/download",
    "ERR458503": "https://osf.io/px7sf/download"
}

# List of samples for Snakemake to iterate over
SAMPLES = list(SAMPLES_MAP.keys())
GENOME = ["ecoli-rel606"]

rule all:
    input:
        expand("outputs/{sample}.x.{genome}.vcf",
               sample=SAMPLES, genome=GENOME),
        expand("outputs/{sample}.x.{genome}.vep.txt",
               sample=SAMPLES, genome=GENOME)

# Rule to download the data using the dictionary URLs
rule download_data:
    output: "{sample}.fastq.gz"
    params:
        url = lambda wildcards: SAMPLES_MAP[wildcards.sample]
    shell: """
        curl -L {params.url} > {output}
    """

rule uncompress_genome:
    input: "{genome}.fa.gz"
    output: "outputs/{genome}.fa"
    shell: """
        gunzip -c {input} > {output}
    """

rule map_reads:
    input:
        reads="{sample}.fastq.gz",
        ref="outputs/{genome}.fa"
    output: "outputs/{sample}.x.{genome}.sam"
    conda: "mapping"
    shell: """
        bwa mem {input.ref} {input.reads} > {output}
    """
