FROM openshift/origin

# Jenkins image for OpenShift
#
# This image provides a Jenkins server, primarily intended for integration with
# OpenShift v3.
MAINTAINER Transformation Team 

ENV JENKINS_RPM_VERSION 2.222.3-1.1
ENV GIT_VERSION 2.21.0

# Jenkins LTS packages from
# https://pkg.jenkins.io/redhat-stable/
ENV JENKINS_VERSION=2 \
    HOME=/var/lib/jenkins \
    JENKINS_HOME=/var/lib/jenkins \
    JENKINS_UC=https://updates.jenkins.io \
    OPENSHIFT_JENKINS_IMAGE_VERSION=5.2 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    ORACLE_HOME=/opt/openshift/SQLPLUS/instantclient_12_2
    
ENV LD_LIBRARY_PATH "$ORACLE_HOME"
ENV PATH "$ORACLE_HOME:$PATH"

RUN echo $PATH
RUN echo "Updated Docker File"


LABEL k8s.io.description="Jenkins is a continuous integration server" \
      k8s.io.display-name="Jenkins 2" \
      openshift.io.expose-services="8080:http" \
      openshift.io.tags="jenkins,jenkins2,ci" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i

# 8080 for main web interface, 50000 for slave agents
EXPOSE 8080 50000

RUN curl https://pkg.jenkins.io/redhat-stable/jenkins.repo -o /etc/yum.repos.d/jenkins.repo && \
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins-ci.org.key && \
    yum install -y centos-release-scl-rh && \
    curl https://copr.fedorainfracloud.org/coprs/alsadi/dumb-init/repo/epel-7/alsadi-dumb-init-epel-7.repo -o /etc/yum.repos.d/alsadi-dumb-init-epel-7.repo && \
    #x86_EXTRA_RPMS=$(if [ "$(uname -m)" == "x86_64" ]; then echo -n java-1.8.0-openjdk.i686 java-1.8.0-openjdk-devel.i686 ; fi) && \
    yum group install 'Development Tools'
    INSTALL_PKGS="gcc dejavu-sans-fonts rsync gettext git tar zip unzip openssl bzip2 dumb-init java-1.8.0-openjdk java-1.8.0-openjdk-devel gettext-devel openssl-devel perl-CPAN perl-devel perl-core zlib-devel" && \
    yum -y --setopt=tsflags=nodocs install $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all  && \
    localedef -f UTF-8 -i en_US en_US.UTF-8
    
ADD jenkins-${JENKINS_RPM_VERSION}.noarch.rpm /tmp
RUN curl https://copr.fedorainfracloud.org/coprs/alsadi/dumb-init/repo/epel-7/alsadi-dumb-init-epel-7.repo -o /etc/yum.repos.d/alsadi-dumb-init-epel-7.repo && \
    yum -y group install "Development Tools" && \
    rpm -ivh /tmp/jenkins-${JENKINS_RPM_VERSION}.noarch.rpm

    
# Configure instance timezone
RUN ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime

COPY ./contrib/openshift /opt/openshift
COPY ./contrib/jenkins /usr/local/bin
ADD ./contrib/s2i /usr/libexec/s2i
ADD release.version /tmp/release.version

# install latest version of GIT
WORKDIR /usr/src
RUN wget https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz -O git.tar.gz && \
    tar xzf git.tar.gz
WORKDIR /usr/src/git-${GIT_VERSION}
RUN make configure && \
    ./configure --prefix=/usr/local && \
    make install
RUN git --version

RUN chmod 775 /usr/local/bin/install-plugins.sh && \
    chmod 775 /usr/local/bin/fix-permissions && \
    chmod 775 /usr/libexec/s2i/run


RUN /usr/local/bin/install-plugins.sh /opt/openshift/base-plugins.txt && \
    # need to create <plugin>.pinned files when upgrading "core" plugins like credentials or subversion that are bundled with the jenkins server
    # Currently jenkins v2 does not embed any plugins, but for reference:
    # touch /opt/openshift/plugins/credentials.jpi.pinned && \
    rmdir /var/log/jenkins && \
    chmod 664 /etc/passwd && \
    chmod -R 775 /etc/alternatives && \
    chmod -R 775 /var/lib/alternatives && \
    chmod -R 775 /usr/lib/jvm && \
    chmod 775 /usr/bin && \
    chmod 775 /usr/lib/jvm-exports && \
    chmod 775 /usr/share/man/man1 && \
    chmod 775 /var/lib/origin && \
    unlink /usr/bin/java && \
    unlink /usr/bin/jjs && \
    unlink /usr/bin/keytool && \
    unlink /usr/bin/orbd && \
    unlink /usr/bin/pack200 && \
    unlink /usr/bin/policytool && \
    unlink /usr/bin/rmid && \
    unlink /usr/bin/rmiregistry && \
    unlink /usr/bin/servertool && \
    unlink /usr/bin/tnameserv && \
    unlink /usr/bin/unpack200 && \
    unlink /usr/lib/jvm-exports/jre && \
    unlink /usr/share/man/man1/java.1.gz && \
    unlink /usr/share/man/man1/jjs.1.gz && \
    unlink /usr/share/man/man1/keytool.1.gz && \
    unlink /usr/share/man/man1/orbd.1.gz && \
    unlink /usr/share/man/man1/pack200.1.gz && \
    unlink /usr/share/man/man1/policytool.1.gz && \
    unlink /usr/share/man/man1/rmid.1.gz && \
    unlink /usr/share/man/man1/rmiregistry.1.gz && \
    unlink /usr/share/man/man1/servertool.1.gz && \
    unlink /usr/share/man/man1/tnameserv.1.gz && \
    unlink /usr/share/man/man1/unpack200.1.gz && \
    chown -R 1001:0 /opt/openshift && \
    /usr/local/bin/fix-permissions /opt/openshift && \
    /usr/local/bin/fix-permissions /opt/openshift/configuration/init.groovy.d && \
    /usr/local/bin/fix-permissions /var/lib/jenkins && \
    /usr/local/bin/fix-permissions /var/log

# SQLPlus

RUN mkdir -p /opt/openshift/SQLPLUS
COPY ./sqlplus /opt/openshift/SQLPLUS

# copy ./SQLPLus/instantclient-sqlplus-linux.x64-12.2.0.1.0.zip /var/lib/jenkins/Oracle

RUN cd /opt/openshift/SQLPLUS && \
    unzip instantclient-basic-linux.x64-12.2.0.1.0.zip && \
    unzip instantclient-sqlplus-linux.x64-12.2.0.1.0.zip
    
COPY ./sqlplus/lib/libaio.so.1 /opt/openshift/SQLPLUS/instantclient_12_2
COPY ./sqlplus/lib/libaio.so.1.0.0 /opt/openshift/SQLPLUS/instantclient_12_2
COPY ./sqlplus/lib/libaio.so.1.0.1 /opt/openshift/SQLPLUS/instantclient_12_2


RUN alternatives --auto java

# Tenporary fix for dns issue
RUN echo "10.232.127.14   nexus.ah.nl" >> /etc/hosts

VOLUME ["/var/lib/jenkins"]

USER 1001
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/libexec/s2i/run"]
