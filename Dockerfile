FROM ubuntu:16.04

MAINTAINER Oskar Vidarsson

#-------------- Install Base

RUN apt-get update && apt-get install -y \
bwa \
wget \
unzip \
python-all \
ruby \
&& rm -rf /var/lib/apt/lists/*

#-------------- Install GATK3.5

ADD GATK3_bin/GATK3.zip /
RUN cd /  && \
    unzip GATK3.zip  && \
    rm GATK3.zip && mkdir /Jar && \
    ln -s /GATK3/GenomeAnalysisTK.jar /Jar/GenomeAnalysisTK.jar  && \
    ln -s /GATK3/picard.jar /Jar/picard.jar && \
    chmod -R ugo+rX /GATK3

#-------------- Install the workflow engine

ADD rbFlow_Engine/rbFlow.zip /
RUN cd / && unzip rbFlow.zip && rm rbFlow.zip
ADD rbFlow_Engine/tool_modules /rbFlow/lib/tool_modules
ENV PATH $PATH:/rbFlow/bin/

#--------------- Install Java 8

RUN mkdir /opt/jdk && cd /opt && \
wget --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u5-b13/jdk-8u5-linux-x64.tar.gz && \
tar -zxf jdk-8u5-linux-x64.tar.gz -C /opt/jdk && \
rm jdk-8u5-linux-x64.tar.gz && \
update-alternatives --install /usr/bin/java java /opt/jdk/jdk1.8.0_05/bin/java 100 && \
update-alternatives --install /usr/bin/javac javac /opt/jdk/jdk1.8.0_05/bin/javac 100

#-------------- Clean

RUN rm -rf /usr/share/locale/ /usr/share/man/ /root/.cache

#-------------- Fix permissions

RUN chmod -R ugo+rX /Jar && \
    chmod -R ugo+rX /GATK3

######
#
#------------- Add Workflows
#
######

WORKDIR /Data
