FROM centos:centos7

MAINTAINER Rainer Hörbe r2h2@hoerbe.at

RUN yum -y update \
 && yum -y install curl iproute lsof openssl tar unzip which wget \
 && yum clean all

# Java
COPY install/downloads/jre1.8.0 /opt/jre1.8.0
ENV JAVA_HOME=/opt/jre1.8.0
ENV PATH=$PATH:$JAVA_HOME/bin:/opt/scripts
RUN echo "export JAVA_HOME=$JAVA_HOME" >> /root/.bashrc \
 && echo "export PATH=$PATH:$JAVA_HOME/bin:/opt/scripts" >> /root/.bashrc

# Jetty
COPY install/downloads/jetty /opt/jetty
COPY install/downloads/jetty/bin/jetty.sh /etc/init.d/jetty
COPY install/jetty-base /opt/jetty-base/
ARG USERNAME=jetty
ARG UID
RUN groupadd --gid $UID $USERNAME \
 && useradd --gid $UID --uid $UID $USERNAME \
 && chown $USERNAME:$USERNAME /run \
 #&& chown -R $USERNAME:$USERNAME /opt/jetty \
 && chown -R $USERNAME:$USERNAME /opt/jetty-base

# Shibboleth IDP
COPY install/downloads/shibboleth-idp-distribution /opt/shibboleth-idp-distribution

COPY install/scripts /opt/scripts/
RUN chmod -R +x /opt/scripts/
# 8443 (browser TLS), 9443 SOAP, 8080 (no TLS)
EXPOSE 8443 9443
CMD ["/opt/scripts/start.sh"]
