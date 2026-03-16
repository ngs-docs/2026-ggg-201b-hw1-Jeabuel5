# Define sample datasets
SAMPLES = {
    "ERR458496": "https://osf.io/tzagu/download",
    "ERR458503": "https://osf.io/px7sf/download",
    # Add any additional samples if necessary
}

# Define different subset sizes representing different coverages
COVERAGE_SIZES = [400000, 800000, 1200000]  # Adjust according to your desired coverages

rule all:
    input:
        expand("SRR2584857_quast.{subset}", subset=COVERAGE_SIZES),
        expand("SRR2584857_annot.{subset}", subset=COVERAGE_SIZES)

rule subset_reads:
    input:
        "{sample}.fastq.gz",
    output:
        "{sample}.{subset}.fastq.gz"
    params:
        subset=lambda wildcards: wildcards.subset
    shell: """
        gunzip -c {input} | head -{params.subset} | gzip -9c > {output} || true
    """

rule assemble:
    input:
        r1 = "SRR2584857_1.{subset}.fastq.gz",
        r2 = "SRR2584857_2.{subset}.fastq.gz"
    output:
        dir = directory("SRR2584857_assembly.{subset}"),
        assembly = "SRR2584857-assembly.{subset}.fa"
    shell: """
       megahit -1 {input.r1} -2 {input.r2} -f -m 5e9 -t 4 -o {output.dir}
       cp {output.dir}/final.contigs.fa {output.assembly}
    """

rule annotate:
    input:
        "SRR25857-assembly.{subset}.fa"
    output:
        directory("SRR2584857_annot.{subset}")
    shell: """
       prokka --prefix {output} {input}                                        
    """

rule quast:
    input:
        "SRR25857-assembly.{subset}.fa"
    output:
        directory("SRR2584857_quast.{subset}")
    shell: """                                                                
       quast {input} -o {output}                                              
    """
