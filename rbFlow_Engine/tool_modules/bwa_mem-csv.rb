---
info:
  name: "Preprocessing_FastQ_to_BAM"
  desc: "Ghislain Fournous"
  log_dir: "output/Logs"
  steps_status_dir: "output/FinishedSteps"


workflow_steps:


#
# Mapping
#

-
  tool: "BWA_MEM_CSV"
  id: "bwa_mem_loop"
  desc: "BWA-mem_csv"
  depend_from: ""
  step_options:
    bwa_bin: "bwa"
    core: 16
    input_csv: "/Workflow/input.csv"
    output_dir: "output/01_mapping_bwa"
    output_suffix: "_map"
    bwa_index: "references//human_g1k_v37_decoy.fasta"
  command_line_options:
    bwa:
      - "-M"


#
# PreProcessing
#

-
  tool: "Picard2MultiInput"
  id: "Picard_SortMergeSam"
  desc: "picard sorting"
  depend_from: ["bwa_mem_loop"]
  step_options:
    input_dir: "output/01_mapping_bwa"
    input_files: "*.sam"
    output_dir: "output/02_bamsorted"
    output_suffix: "_sorted"
    java_bin: "java"
    picard2_jar: "/Jar/picard.jar"
    picard2_command: "MergeSamFiles"
  command_line_options:
    java:
      - "-Xmx15G"
      - "-Djava.io.tmpdir=/tmp"
    picard2:
      - "CREATE_INDEX=true"
      - "USE_THREADING=true"
      - "MAX_RECORDS_IN_RAM=1000000"
      - "SORT_ORDER=coordinate"
      - "VALIDATION_STRINGENCY=LENIENT"

-
  tool: "Picard2"
  id: "picard_mark_duplicate"
  desc: "picard mark duplicate and merge lanes"
  depend_from: ["Picard_SortMergeSam"]
  step_options:
    input_dir: "output/02_bamsorted"
    input_files: "*.bam"
    output_dir: "output/03_markdup"
    output_suffix: "_markdup"
    java_bin: "java"
    picard2_jar: "/Jar/picard.jar"
    picard2_command: "MarkDuplicates"
  command_line_options:
    java:
      - "-Xmx15G"
      - "-Djava.io.tmpdir=/tmp"
    picard2:
      - "METRICS_FILE=samples.metrics"
      - "VALIDATION_STRINGENCY=LENIENT"
      - "CREATE_INDEX=true"
      - "MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=1000"

-
  tool: "GATK_BaseRecalibrator_PrintReads"
  id: "GATK_BaseRecalibrator"
  desc: "GATK Fix Mate Base Recalibration"
  depend_from: ["picard_mark_duplicate"]
  result: "true"
  step_options:
    core: 10
    input_dir: "output/03_markdup"
    input_files: "*.bam"
    output_dir: "output/04_gatk_recal"
    output_suffix: "_recalib"
    java_bin: "java"
    gatk_jar: "/Jar/GenomeAnalysisTK.jar"
    ref_path:   "references//human_g1k_v37_decoy.fasta"
  command_line_options:
    java:
      - "-Xmx15G"
      - "-Djava.io.tmpdir=/tmp"
    gatk:
      - " "
    gatk_recal:
      - " -knownSites references/1000g.vcf "
      - " -knownSites references/Mills_and_1000G_gold_standard.indels.b37.vcf "
      - " -knownSites references/dbsnp.vcf "
      - " -cov ContextCovariate "
      - " -cov CycleCovariate "
    gatk_PrintReads:
      - ""

