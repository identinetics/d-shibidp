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
COPY install/jetty-base /opt/default/jetty-base
# Shibboleth IDP
COPY install/downloads/shibboleth-idp-distribution /opt/shibboleth-idp-distribution

# The IdP status page depends on the JSP Standard Tag Library, which is not part of the distribution
RUN mkdir -p /opt/shibboleth-idp-distribution/edit-webapp/WEB-INF/lib \
 && cd /opt/shibboleth-idp-distribution/edit-webapp/WEB-INF/lib \
 && curl -O https://repo1.maven.org/maven2/jstl/jstl/1.2/jstl-1.2.jar
# To rebuild idp.war: use /rebuild_idp_war.sh in the container

COPY install/scripts/*.sh /
RUN chmod -R +x /*.sh
# 8443 (browser TLS), 9443 SOAP, 8080 (no TLS)
# do not expose ports, but use proxy for 8080 instead
# EXPOSE 8443 9443
CMD ["/start.sh"]

ARG USERNAME=jetty
ARG UID=1000
RUN groupadd --gid $UID $USERNAME \
 && useradd --gid $UID --uid $UID $USERNAME \
 && chown $USERNAME:$USERNAME /run \
 && chown -R $USERNAME:$USERNAME /opt/default/jetty-base \
 && chown -R $USERNAME:$USERNAME /opt/shibboleth-idp-distribution
