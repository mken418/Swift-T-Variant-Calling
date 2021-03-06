# Variant Calling with Swift-T

## Intended pipeline architecture and function

This pipeline implements the [GATK's best practices](https://software.broadinstitute.org/gatk/best-practices/) for germline variant calling in Whole Genome and Whole Exome Next Generation Sequencing datasets, given a cohort of samples.

This pipeline was disigned for GATK 3.X, which include the following stages:

1.  Map to the reference genome
2.  Mark duplicates
3.  Perform indel realignment and/or base recalibration (BQSR)\*
4.  Call variants on each sample
5.  Perform joint genotyping

\* The indel realignment step was recommended in GATK best practices \< 3.6). 

Additionally, this workflow provides the option to split the aligned reads by chromosome before calling variants, which often speeds up performance when analyzing WGS data. 

<img src=./media/WorkflowOverview.png width="600">

**Figure 1** Overview of Workflow Design

## Installation

### Dependencies

|  **Stage**          |  **Tool options**                                                             |
| --------------------| ------------------------------------------------------------------------------|
|  Alignment          | [Bwa mem](https://github.com/lh3/bwa) or [Novoalign](http://novocraft.com/)   |
|  Sorting            | [Novosort](http://novocraft.com/)                                             |
|  Marking Duplicates | [Samblaster](https://github.com/GregoryFaust/samblaster), [Novosort](http://novocraft.com/), or [Picard](https://broadinstitute.github.io/picard/)                                                    |
|  Indel Realignment  | [GATK](https://software.broadinstitute.org/gatk/download/)                    |
|  Base Recalibration | [GATK](https://software.broadinstitute.org/gatk/download/)                    |
|  Variant Calling    | [GATK](https://software.broadinstitute.org/gatk/download/)                    |
|  Joint Genotyping   | [GATK](https://software.broadinstitute.org/gatk/download/)                    |
|  Miscellaneous      | [Samtools](http://samtools.github.io/)                                        |
 
### Workflow Installation

Clone this repository

## User Guide
The workflow is controlled by modifying the variables contained within a runfile.

A `template.runfile` is packaged within this repo.

From this file, one specifies how the workflow is ran

### Runfile Options

**`SAMPLEINFORMATION`**

The file that contains the paths to each sample's reads

Each sample is on its own line in the form: `SampleName /path/to/read1.fq /path/to/read2.fq`

If analyzing single-end reads, the format is simply: `SampleName /path/to/read1.fq`

**`OUTPUTDIR`** The path that will serve as the root of all of the output files generated from the pipeline (See Figure XXXXXXXXXX)

**`DELIVERYFOLDER`** Name of the delivery folder (See Figure XXXXXXXX)

**`TMPDIR`** The path to where temporary files will be stored

**`ANALYSIS`**

Set the type of analysis being conducted:

| **Analysis**                          | **Setting**                           |
| --------------------------------------|---------------------------------------|
|  Alignment only                       | `ALIGN`, `ALIGN_ONLY`, or `ALIGNMENT` |
|  Variant Calling with Realignment     | `VC_REALIGN`                          |
|  Variant Calling without Realignment  | \<Any other non-empty string\>        |

**`SPLIT`** YES if one wants to split-by-chromosome before calling variants, NO if not.

**`PROCPERNODE`**

This stands for processes per node.

Sometimes it is more efficent to double (or even triple) up runs of an application on the same nodes using half of the available threads than letting one run of the application use all of them. This is because many applications only scale well up to a certain number of threads, and often this is less than the total number of cores available on a node.

Under the hood, this variable simply controls how many threads each tool gets. If `PBSCORES` is set to 20 but `PROCPERNODE` is set to 2, each tool will use up to 10 threads. It is up to the user at runtime to be sure that the right number of processes are requested per node when calling Swift-T itself (See section XXXXXXXXXXXXXX), as this is what actually controls how processes are distributed.

**`EXIT_ON_ERROR`**

If this is set to `YES`, the workflow will quit after a fatal error occurs in any of the samples.

If set to `NO`, the workflow will let samples fail, and continue processing all of those that did not. The workflow will only stop if none of the samples remain after the failed ones are filtered out.

This option is provided because for large sample sets one may expect a few of the input samples to be malformed in some way, and it may be acceptable to keep going if a few fail. However, exercise caution and monitor the `Failures.log` generated in the `DELIVERYFOLDER/docs` folder to gauge how many of the samples are failing.

**`ALIGN_DEDUP_STAGE`; `CHR_SPLIT_STAGE`; `VC_STAGE`; `COMBINE_VARIANT_STAGE`; `JOINT_GENOTYPING_STAGE`**

These variables control whether each stage is ran or skipped (only stages that were successfully run previously can be skipped, as the "skipped" option simply looks for the output files that were generated from a previous run.)

Each of these stage variables can be set to `Y` or `N`. In addition, all but the last stage can be set to `End`, which will stop the pipeline after that stage has been executed (think of the `End` setting as shorthand for "End after this stage")

See the **Pipeline Interruptions and Continuations** Section for more details.

**PAIRED** 0 if reads are single-ended only; 1 if they are paired-end reads

**ALIGNERTOOL; MARKDUPLICATESTOOL**

| **Process**     | **Setting**                           |
| ----------------|---------------------------------------|
| Alignment       | `BWAMEM` or `NOVOALIGN`               |              
| Mark Duplicates | `SAMBLASTER`, `PICARD`, or `NOVOSORT` |

**`BWAINDEX`; `NOVOALIGNINDEX`** Depending on the tool being used, one of these variables specify the location of the index file

**`BWAMEMPARAMS`; `NOVOALIGNPARAMS`**

This string is passed directly as arguments to the tool as (an) argument(s)

Example, `BWAMEMPARAMS=-k 32 -I 300,30`

Note: Do not set the thread count, as this flag is taken care of by the workflow itself

**`CHRNAMES`**

List of chromosome/contig names separated by a ':'

Examples:
* `chr1:chr2:chr3`
* `1:2:3`

Note: chromosome names must match those found in the files located in the directory that `INDELDIR` points to

**`NOVOSORT_MEMLIMIT`**

Novosort is a tool that used a lot of RAM. If doubling up novosort runs on the same node, this may need to be reduced to avoid an OutOfMemory Error. Otherwise, just set it to most of the RAM on a node

This is set in bytes, so if you want to limit novosort to using 30 GB, one would set it to `NOVOSORT_MEMLIMIT=30000000000`

**`MAP_CUTOFF`** The minimum percentage of reads that were successfully mapped in a successful alignment

**`DUP_CUTOFF`** The maximum percentage of reads that are marked as duplicates in a successful sample

**`REFGENOMEDIR`** Directory in which the reference genome resides

**`REFGENOME`** Name of the reference genome (name only, not full path)

**`DBSNP`** Name of the dbsnp vcf file (name only, path should be that of the REFGENOMEDIR

**`INDELDIR`** Directory that contains the indel variant files used in the recalibration step

**`OMNI`** \< Insert explanation here \> Not currently used in workflow

**`JAVAEXE`; `BWAEXE`; `SAMBLASTEREXE`; `SAMTOOLSEXE`; `NOVOALIGNEXE`; `NOVOSORTEXE`**

Full path of the appropriate executable file

**`PICARDJAR`; `GATKJAR`** Full path of the appropriate jar file

### Running the Pipeline

#### Executing the Swift-T Application 

`swift-t -O3 -o </path/to/compiled_output_file.tic> -I /path/to/Swift-T-Variant-Calling/src -r /path/to/Swift-T-Variant-Calling/src/bioapps -u -n < Node# * PROCPERNODE + 1 or more > /path/to/Swift-T-Variant-Calling/src/VariantCalling.swift -runfile=/path/to/example.runfile`

This command will compile and run the pipeline all in one command

**Explanation of flags**

* `-O3` Conduct full optimizations of the Swift-T code during compilation (Even with full optimizations, compilation of the code takes only around 3 seconds)
* `-o` The path to the compiled swift-t file (has a .tic extension); on the first run, this file will be created.
* `-I` This includes some source files that are imported during compilation
* `-r` This includes some tcl package files needed during compilation
* `-u` Specifies that the Swift-T code will be compiled only if an already up-to-date version is not found
* `-n` The number of processes (ranks) Swift-T will open for this run of the workflow
* `-runfile` The path to the runfile with all of the configuration variables for the workflow

This command must be included in a job submission script and not called directly on a head/login node.

#### Requesting Resources from the Job Scheduler

Swift-T works by opening up multiple "slots", called processes, where applications can run. There are two types of processes this workflow allocates
* SERVERS - Control the execution of Swift-T itself; all Swift-T applications must have at least one of these
* WORKERS - Run the actual work of each application in the workflow; these will make up the vast majority of processes

It is important to note that (at least for PBS Torque schedulers) when submitting a qsub script, ppn option should be set, not to the number of cores on each compute node, but to the number of WORKERS Swift-T needs to open up on that node. 

**Example**

If one is wanting to run a 4 sample job with `PROCPERNODE` set to 2 in the runfile (meaning that two bwa runs can be executing simultaneously on a given node, for example), one would set the PBS flag to `-l nodes=2:ppn=2` and the `-n` flag when calling the workflow to 5 \( nodes\*ppn + 1 \)

#### Logging Options

While the outputs generated by all the tools of the workflow itself will be logged in the log folders within the `OUTDIR` structure, Swift-T generates a log itself that may help debug if problems occur.

Setting the environment variable `TURBINE_LOG` to 1 will make the log quite verbose

Setting `ADBL_DEBUG_RANKS` to 1 will allow one to be sure the processes are being allocated to the nodes in the way one expects

### Output Structure

TO-DO make better Figure

![](./media/image04.png)

Figure 3: Output directories and files generated from a typical run of
the pipeline

### Data preparation

For this pipeline to work, a number of standard files for calling variants are needed (besides the raw reads files which can be fastq/fq/fastq.gz/fq.gz), namely these are the reference sequence and database of known variants (Please see this [link](https://software.broadinstitute.org/gatk/guide/article?id=1247)).

For working with human data, one can download most of the needed files from [the GATK’s resource bundle](http://gatkforums.broadinstitute.org/gatk/discussion/1213/whats-in-the-resource-bundle-and-how-can-i-get-it). Missing from the bundle are the index files for the aligner, which are specific to the tool that would be used for alignment (i.e., bwa or novoalign in this pipeline)

Generally, for the preparation of the reference sequence, the following link is a good start [the GATK’s guidelines](http://gatkforums.broadinstitute.org/wdl/discussion/2798/howto-prepare-a-reference-for-use-with-bwa-and-gatk).

If splitting by chromosome for the realignment/recalibration/variant-calling stages, the pipeline needs a separate vcf file of known variants for each chromosome/contig, and each should be named as: `*${chr_name}.vcf` . Further, all these files need to be in the `INDELDIR` which should be within the `REFGENOMEDIR` directory as per the runfile.

### Resource Requirements

|  **Analysis Stage**                              |  **Resource Requirements**
| ------------------------------------------------ | -------------------------
|  Alignment and Deduplication                     | Nodes = Samples / (Processes per Node\*)
|  Split by Chromosome/Contig                      | Processes = Samples * Chromosomes<br>Nodes = Processes/ (Cores per Node)
|  Realignment, Recalibration, and Variant Calling | Nodes = [Samples / (Processes per Node\*)] * Chromosomes
|  Combine Sample Variants                         | Nodes = Samples / (Processes per Node\*)
** Table 1: Pipeline tools **

\*Running 10 processes using 20 threads in series may actually be slower than running the 10 processes in pairs utilizing 10 threads each

## Pipeline Interruptions and Continuations

### Background

Because of the varying resource requirements at various stages of the pipeline, the workflow allows one to stop the pipeline at many stages and jump back in without having to recompute.

This feature is controlled by the STAGE variables of the runfile. At each stage, the variable can be set to "Y" if it should be computed, and "N" if that stage was completed on a previous execution of the workflow. If "N" is selected, the program will simply gather the output that should have been generated from a previous run and pass it to the next stage.

In addition, one can set each stage but the final one to "End", which will stop the pipeline after that stage has been executed. Think of "End" as a shorthand for "End after this stage".

### Example

If splitting by chromosome, it may make sense to request different resources at different times.

One may want to execute only the first two stages of the workflow with # Nodes = # Samples. For this step, one would use these settings:

 * ALIGN_DEDUP_STAGE=Y
 * CHR_SPLIT_STAGE=End         # This will be the last stage that is executed
 * VC_STAGE=N
 * COMBINE_VARIANT_STAGE=N
 * JOINT_GENOTYPING_STAGE=N

Then for the variant calling step, where the optimal resource requirements may be something like # Nodes = (# Samples \* # Chromosomes), one could alter the job submission script to request more resources, then use these settings:

 * ALIGN_DEDUP_STAGE=N
 * CHR_SPLIT_STAGE=N
 * VC_STAGE=End                # Only this stage will be executed
 * COMBINE_VARIANT_STAGE=N
 * JOINT_GENOTYPING_STAGE=N

Finally, for the last two stages, where it makes sense to set # Nodes = # Samples again, one could alter the submission script again and use these settings:

 * ALIGN_DEDUP_STAGE=N
 * CHR_SPLIT_STAGE=N
 * VC_STAGE=N
 * COMBINE_VARIANT_STAGE=Y
 * JOINT_GENOTYPING_STAGE=Y

This feature was designed to allow a more efficient use of computational resources.

## Under The Hood

<img src="./media/ProgramStructure.png" width="600">

**Figure 2: Program Structure**

Each Main function has two paths it can use to produce its output:
1. One path actually performs the computations of this stage of the pipeline
2. The other skips the computations and just gathers the output of a prior execution of this stage. This is useful when one wants to jump into different sections of the pipeline, and also allows Swift/T's dependency driven execution to correctly string the stages together into one workflow.

## Troubleshooting

* The pipeline seems to be running, but then prematurely stops at one of the tools?
  * Solution: make sure that all tools are specified in your runfile up to the executable itself (or the jar file if applicable)

* The realignment/recalibration stage produces a lot of errors or strange results?
  * Solution: make sure you are preparing your reference and extra files (dbsnp, 1000G,...etc) according to the guidelines of section 2.2

* Things that should be running in parallel appear to be running sequencially
  * Solution: make sure you are setting the `-n` flag to a value at least one more than `PROCPERNODE` * `PBSNODES`, as this allocates processes for Swift/T itself to run on

* The job is killed as soon as BWA is called?
  * Solution: make sure there is no space in front of `BWAMEMPARAMS`
    * DO-THIS:  `BWAMEMPARAMS=-k 32 -I 300,30`
    * NOT-THIS: `BWAMEMPARAMS= -k 32 -I 300,30`

* I'm not sure how to run on a cluster that uses torque as a resource manager?
  * Clusters are typically configured to kill head node jobs that run longer than a few minutes, to prevent users from hogging the head node. Therefore, you may qsub the initial job, the swift-t command with its set variables, and it will qsub everybody else from its compute node.
