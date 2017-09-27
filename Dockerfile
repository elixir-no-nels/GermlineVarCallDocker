FROM alpine:3.5
# several value can be provided for the LABEL instruction, but we use here a build with squash option, so it is not important.
LABEL maintainer="Ghislain Fournous"
# Language support
LABEL lang.python="2.7.x"
LABEL lang.julia=""
LABEL lang.Ruby="2.4.x"
LABEL lang.Java="8u112"
# Software installed
LABEL soft.Picard="2.12.x"
#LABEL soft.varscan="2.4.x"
#LABEL soft.Strelka="2.7.x"
LABEL soft.samtools="1.3.x"
#LABEL soft.bedtools="2.26.x"
#LABEL soft.delly="0.7.x"
LABEL soft.bwa="0.7.x"
#LABEL soft.fastqc="0.11.x"
LABEL ext_soft.rbFlow="latest"
# Software locally installed (licence issue)
LABEL ext_soft.GATK="3.7"
LABEL ext_soft.mutect="1.17"



#-------------- Env
ENV PATH $PATH:/usr/local/libexec/:/usr/local/bin/


#-------------- Add APK packages
ENV PKG_BASE="bzip2-dev ca-certificates gnupg libffi-dev libstdc++ openssl-dev yaml-dev procps zlib-dev"
ENV PKG_TEMP="alpine-sdk bash coreutils curl libxml2-dev libxslt-dev linux-headers make ncurses-dev procps readline-dev wget "
ENV PKG_LANG="python perl"
RUN set -ex && \
    apk upgrade --update && \
    apk add --no-cache --update $PKG_BASE $PKG_TEMP $PKG_LANG


#-------------- Install Java_8
# from https://developer.atlassian.com/blog/2015/08/minimal-java-docker-containers/
# Java Version and other ENV
ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=144 \
    JAVA_VERSION_BUILD=01 \
    JAVA_PACKAGE=jdk \
    JAVA_JCE=standard \
    JAVA_HOME=/opt/jdk \
    PATH=${PATH}:/opt/jdk/bin \
    GLIBC_VERSION=2.23-r3 \
    LANG=C.UTF-8

# do all in one step
RUN set -ex && \
    apk upgrade --update && \
    apk add --update libstdc++ curl ca-certificates bash && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --allow-untrusted /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
    mkdir /opt && \
    curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/java.tar.gz \
      http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/090f390dda5b47b9b721c7dfaa008135/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz && \
    gunzip /tmp/java.tar.gz && \
    tar -C /opt -xf /tmp/java.tar && \
    ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk && \
    if [ "${JAVA_JCE}" == "unlimited" ]; then echo "Installing Unlimited JCE policy" >&2 && \
      curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip \
        http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
      cd /tmp && unzip /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
      cp -v /tmp/UnlimitedJCEPolicyJDK8/*.jar /opt/jdk/jre/lib/security; \
    fi && \
    sed -i s/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=10/ $JAVA_HOME/jre/lib/security/java.security && \
    apk del curl glibc-i18n && \
    rm -rf /opt/jdk/*src.zip \
           /opt/jdk/lib/missioncontrol \
           /opt/jdk/lib/visualvm \
           /opt/jdk/lib/*javafx* \
           /opt/jdk/jre/plugin \
           /opt/jdk/jre/bin/javaws \
           /opt/jdk/jre/bin/jjs \
           /opt/jdk/jre/bin/orbd \
           /opt/jdk/jre/bin/pack200 \
           /opt/jdk/jre/bin/policytool \
           /opt/jdk/jre/bin/rmid \
           /opt/jdk/jre/bin/rmiregistry \
           /opt/jdk/jre/bin/servertool \
           /opt/jdk/jre/bin/tnameserv \
           /opt/jdk/jre/bin/unpack200 \
           /opt/jdk/jre/lib/javaws.jar \
           /opt/jdk/jre/lib/deploy* \
           /opt/jdk/jre/lib/desktop \
           /opt/jdk/jre/lib/*javafx* \
           /opt/jdk/jre/lib/*jfx* \
           /opt/jdk/jre/lib/amd64/libdecora_sse.so \
           /opt/jdk/jre/lib/amd64/libprism_*.so \
           /opt/jdk/jre/lib/amd64/libfxplugins.so \
           /opt/jdk/jre/lib/amd64/libglass.so \
           /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
           /opt/jdk/jre/lib/amd64/libjavafx*.so \
           /opt/jdk/jre/lib/amd64/libjfx*.so \
           /opt/jdk/jre/lib/ext/jfxrt.jar \
           /opt/jdk/jre/lib/ext/nashorn.jar \
           /opt/jdk/jre/lib/oblique-fonts \
           /opt/jdk/jre/lib/plugin.jar \
           /tmp/* /var/cache/apk/* && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# EOF


#--------------  Install Ruby verion 2.4.0
RUN wget https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.0.tar.gz && \
    tar xvfz ruby-2.4.0.tar.gz && \
    cd ruby-2.4.0 && \
    ./configure && \
    make install && \
    cd / && \
    rm ruby-2.4.0.tar.gz && \
    rm -rf ruby-2.4.0 && \
    gem update --system && \
    gem update
    #gem install --no-document rdoc rake


#-------------- Install cpanminus
#RUN curl -LO https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm && \
#    chmod +x cpanm && \
#    mv cpanm /usr/bin/  && \
#    cpanm App::cpanminus


#-------------- Install Julia
#RUN apk add julia --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted


#-------------- Install the workflow engine
COPY rbFlow /
RUN rm -rf /rbFlow/.git
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
RUN wget https://github.com/lh3/bwa/releases/download/v0.7.15/bwakit-0.7.15_x64-linux.tar.bz2 && \
    tar xvjf bwakit-0.7.15_x64-linux.tar.bz2 && \
    cp bwa.kit/bwa /usr/local/bin/ && \
    rm -rf bwa.kit && \
    rm bwakit-0.7.15_x64-linux.tar.bz2


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
