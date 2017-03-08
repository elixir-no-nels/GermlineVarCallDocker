# GermlineVarCallDocker

This Docker image contain a collection of tool for NGS analysis, there is also included rbFlow, a small and simple workflow engine.

# Tools included

### Language support
- python="2.7.x"
- Ruby="2.4.x"
- Java="8u112"

### Software installed
- Picard="2.8.x"
- varscan="2.3.x"
- Strelka="2.7.x"
- samtools="1.3.x"
- bedtools="2.26.x"
- delly="0.7.x"
- bwa="0.7.x"
- fastqc="0.11.x"
- rbFlow="latest"

### Software locally installed (licence issue)
- GATK="3.7"
- mutect="1.17"

### Instructions for downloading the reference files for this pipeline
If you are part of a Norwegian university you have access to the NeLS portal, which is where we store the official reference files for this pipeline. If you have never used scp to download files from NeLS, watch [this tutorial](https://www.youtube.com/watch?v=TbUl8iuIwIw) for a guided walkthrough for how to download files from NeLS.  
Once you have your ssh private key file, you can copy and paste the code below, edit it and put in your NeLS username that you got in the tutorial. The NeLS file path should be the same as the one in the code below, but you need to edit the destination file path by changing "/your/destination/" to your actual folder where the reference files will be located.

```
scp -r -i yourNeLSusername@nelstor0.cbu.uib.no.txt yourNeLSusername@nelstor0.cbu.uib.no:Projects/NCS-PM_Elixir_collaboration/Germline-varcall-wf-reference-files-v2.8/ /your/destination/
```

You can also download it using the graphical user interface if you prefer that, in that case you log in to NeLS and navigate to the "/Projects/NCS-PM_Elixir_collaboration" folder and click the zip file icon to download the entire folder as a zip file.