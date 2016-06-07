FROM centos:centos7

MAINTAINER Rainer Hörbe r2h2@hoerbe.at

RUN yum -y update \
 && yum -y install curl iproute lsof net-tools openssl tar unzip which wget \
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
ARG USERNAME
ARG UID
RUN groupadd --gid $UID $USERNAME \
 && useradd --gid $UID --uid $UID $USERNAME \
 && chown $USERNAME:$USERNAME /run \
 && chown -R $USERNAME:$USERNAME /opt/jetty-base \
 && mkdir -p /var/log/jetty/ /etc/shib-idp/ \
 && ln -s /opt/jetty-base/logs /var/log/jetty/ \
 && ln -s /opt/shibboleth-idp/conf/ /etc/shib-idp/

# Shibboleth IDP
COPY install/downloads/shibboleth-idp-distribution /opt/shibboleth-idp-distribution
RUN chown -R $USERNAME:$USERNAME /opt/shibboleth-idp-distribution

COPY install/scripts/*.sh /
RUN chmod -R +x /*.sh
# 8443 (browser TLS), 9443 SOAP, 8080 (no TLS)
# do not expose ports, but use proxy for 8080 instead
# EXPOSE 8443 9443
CMD ["/start.sh"]
