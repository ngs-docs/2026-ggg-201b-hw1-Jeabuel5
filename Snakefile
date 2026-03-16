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

# Rule to download the raw fastq data
rule download_data:
    output: "{sample}.fastq.gz"
    params:
        url = lambda wildcards: SAMPLES_MAP[wildcards.sample]
    shell: """
        curl -L {params.url} > {output}
    """

# Rule to download the reference genome
rule download_genome:
    output: "{genome}.fa.gz"
    shell: """
        curl -L https://osf.io/vru9s/download > {output}
    """

# Rule to download the GFF annotation
rule download_gff:
    output: "ecoli-rel606.gff"
    shell: """
        curl -L https://osf.io/s7e2d/download > {output}
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

# Rule to sort and compress the GFF (required for tabix)
rule sort_gff:
    input: "ecoli-rel606.gff"
    output: "ecoli-rel606.sorted.gff.gz"
    shell: """
        grep -v '^#' {input} | sort -k1,1 -k4,4n | bgzip > {output}
    """

# Rule to index the GFF
rule tabix:
    input: "{filename}.gff.gz"
    output: "{filename}.gff.gz.tbi"
    shell: """
        tabix -p gff {input}
    """

rule sam_to_bam:
    input: "outputs/{sample}.x.{genome}.sam"
    output: "outputs/{sample}.x.{genome}.bam"
    shell: "samtools view -S -b {input} > {output}"

rule sort_bam:
    input: "outputs/{sample}.x.{genome}.bam"
    output: "outputs/{sample}.x.{genome}.sorted.bam"
    shell: "samtools sort {input} -o {output}"

rule call_variants:
    input:
        ref="outputs/{genome}.fa",
        bam="outputs/{sample}.x.{genome}.sorted.bam"
    output: "outputs/{sample}.x.{genome}.vcf"
    shell: "bcftools mpileup -f {input.ref} {input.bam} | bcftools call -mv -Ov > {output}"

rule predict_effects:
    input:
        vcf="outputs/{sample}.x.{genome}.vcf",
        gff="ecoli-rel606.sorted.gff.gz",
        tbi="ecoli-rel606.sorted.gff.gz.tbi",
        ref="outputs/{genome}.fa"
    output: "outputs/{sample}.x.{genome}.vep.txt"
    shell: """
        bcftools csq -f {input.ref} -g {input.gff} {input.vcf} -o {output}
    """
