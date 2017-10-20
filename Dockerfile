FROM alpine:3.6
# several value can be provided for the LABEL instruction, but we use here a build with squash option, so it is not important.
LABEL maintainer="Ghislain Fournous"
# Language support
LABEL lang.python="2.7.x"
LABEL lang.julia=""
LABEL lang.Ruby="2.4.x"
LABEL lang.Java="8u131"
# Software installed
LABEL soft.Picard="2.12.x"
#LABEL soft.varscan="2.4.x"
#LABEL soft.Strelka="2.7.x"
LABEL soft.samtools="1.3.x"
#LABEL soft.bedtools="2.26.x"
#LABEL soft.delly="0.7.x"
LABEL soft.bwa="0.7.16x"
#LABEL soft.fastqc="0.11.x"
LABEL ext_soft.rbFlow="latest"
# Software locally installed (licence issue)
LABEL ext_soft.GATK="3.7"
LABEL ext_soft.mutect="1.17"



#-------------- Env
ENV PATH $PATH:/usr/local/libexec/:/usr/local/bin/


#-------------- Add APK packages
ENV PKG_BASE="bzip2-dev ca-certificates gnupg libffi-dev libstdc++ openssl-dev yaml-dev procps zlib-dev"
ENV PKG_TEMP="alpine-sdk bash coreutils curl libxml2-dev libxslt-dev linux-headers make ncurses-dev procps readline-dev wget curl "
ENV PKG_LANG="python openjdk8-jre ruby"
RUN set -ex && \
    apk upgrade --update && \
    apk add --no-cache --update $PKG_BASE $PKG_TEMP $PKG_LANG

# Upgrade ca-certificates
RUN apk update && apk add ca-certificates && update-ca-certificates && apk add openssl

#--------------  Install Ruby verion 2.4.0
#RUN wget https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.0.tar.gz && \
#    tar xvfz ruby-2.4.0.tar.gz && \
#    cd ruby-2.4.0 && \
#    ./configure && \
#    make install && \
#    cd / && \
#    rm ruby-2.4.0.tar.gz && \
#    rm -rf ruby-2.4.0 && \
RUN gem install --no-document rdoc && \
    gem install --no-document rake pry awesome_print


#-------------- Install cpanminus
#RUN set -ex && \
#    apk upgrade --update && \
#    apk add --no-cache --update perl
#RUN curl -LO https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm && \
#    chmod +x cpanm && \
#    mv cpanm /usr/bin/  && \
#    cpanm App::cpanminus


#-------------- Install Julia
#RUN apk add julia --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted


#-------------- Install the workflow engine
COPY rbFlow /rbFlow
RUN rm -rf /rbFlow/.git
RUN chmod -R 644 /rbFlow && chmod -R ugo+X /rbFlow && chmod 755 /rbFlow/bin/*
ENV PATH $PATH:/rbFlow/bin/

#-------------- Create a /Jar directory to store jar files
RUN mkdir /Jar

#-------------- Install Picard
RUN wget https://github.com/broadinstitute/picard/releases/download/2.12.1/picard.jar -O /Jar/picard.jar


#-------------- Install VarScan
#RUN wget https://github.com/dkoboldt/varscan/releases/download/2.4.2/VarScan.v2.4.2.jar -O /Jar/VarScan.jar


#-------------- Install Strelka 2.7.x
#RUN wget https://github.com/Illumina/strelka/releases/download/v2.7.1/strelka-2.7.1.centos5_x86_64.tar.bz2 && \
#    tar xvfj strelka-2.7.1.centos5_x86_64.tar.bz2 && \
#    rm strelka-2.7.1.centos5_x86_64.tar.bz2 && \
#    mv strelka-2.7.1.centos5_x86_64 strelka-2.7.1
#ENV PATH $PATH:/strelka-2.7.1/bin
#RUN rm -rf strelka-2.7.1/share/demo/strelka/


#-------------- samtools 1.3.x
RUN wget https://github.com/samtools/htslib/releases/download/1.3.2/htslib-1.3.2.tar.bz2 && \
    tar xvjf htslib-1.3.2.tar.bz2 && \
    cd /htslib-1.3.2 && \
    make install && \
    cd / && \
    rm -rf htslib-1.3.2* && \
    wget https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 && \
    tar xvjf samtools-1.3.1.tar.bz2 && \
    cd /samtools-1.3.1 && \
    make install && \
    cd / && \
    rm -rf /samtools-1.3.1* && \
    wget https://github.com/samtools/bcftools/releases/download/1.3.1/bcftools-1.3.1.tar.bz2 && \
    tar xvjf bcftools-1.3.1.tar.bz2 && \
    cd /bcftools-1.3.1 && \
    make && make install && \
    cd / && \
    rm -rf bcftools-1.3.1*


#-------------- Install BedTools
#RUN wget https://github.com/arq5x/bedtools2/releases/download/v2.26.0/bedtools-2.26.0.tar.gz && \
#    tar xvfz bedtools-2.26.0.tar.gz && \
#    cd /bedtools2/ && \
#    make && \
#    cp /bedtools2/bin/* /usr/local/bin/ && \
#    cd / && \
#    rm -rf /bedtools2/ && \
#    rm bedtools-2.26.0.tar.gz

#-------------- Install BWA
RUN curl -L https://github.com/lh3/bwa/releases/download/v0.7.15/bwakit-0.7.15_x64-linux.tar.bz2 -O && \
    tar xvjf bwakit-0.7.15_x64-linux.tar.bz2 && \
    cp bwa.kit/bwa /usr/local/bin/ && \
    rm -rf bwa.kit && \
    rm bwakit-0.7.15_x64-linux.tar.bz2

RUN curl -L -O https://github.com/lh3/bwa/releases/download/v0.7.16/bwa-0.7.16a.tar.bz2 && \
    bunzip2 bwa-0.7.16a.tar.bz2 && \
    tar xvf bwa-0.7.16a.tar && \
    cd bwa-0.7.16a/ && \
    make && \
    chmod +x bwa && \
    mv bwa /usr/local/bin && \
    cd .. && \
    rm -rf bwa-0.7.16a*

#-------------- Install FastQC
#RUN wget http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.5.zip && \
#    unzip fastqc_v0.11.5.zip && \
#    rm fastqc_v0.11.5.zip
#ENV PATH $PATH:FastQC


#-------------- Delly 0.7.x
#RUN wget https://github.com/dellytools/delly/releases/download/v0.7.6/delly_v0.7.6_parallel_linux_x86_64bit && \
#    mv delly_v0.7.6_parallel_linux_x86_64bit /usr/local/bin/delly && \
#    chmod +x /usr/local/bin/delly


#-------------- Install GATK3.5 and Mutect1.1.7
COPY GATK3_bin /Jar
RUN mv /Jar/mutect-1.1.7.jar /Jar/mutect.jar


# Cleaning
RUN apk del $PKG_TEMP

# Create the working directory
ENV HOME /tmp/
RUN mkdir /Workflow && chmod 777 /Workflow
WORKDIR /Workflow
