FROM intra/centos7_base
# intra/centos7_base is a synonym to centos:7

LABEL maintainer="Rainer Hörbe <r2h2@hoerbe.at>"

RUN yum -y update \
 && yum -y install curl iproute lsof net-tools openssl tar unzip which wget \
 && yum clean all && rm -rf /var/cache/yum

# Java
ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=181 \
    JAVA_VERSION_BUILD=13 \
    JAVA_URL_HASH=96a7b8442fe848ef90c96a2fad6ed6d1

# Downloading Java
RUN wget --no-cookies --no-check-certificate --no-verbose \
         --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
         "http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_URL_HASH}/jre-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.rpm" \
 && yum localinstall -y jre-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.rpm \
 && rm -f jre-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.rpm \
 && rm -rf /var/cache/yum


ENV JAVA_HOME /usr/java/latest
#ENV JAVA_HOME=/opt/jre1.8.0
ENV PATH=$PATH:$JAVA_HOME/bin:/opt/scripts
RUN echo "export JAVA_HOME=$JAVA_HOME" >> /root/.bashrc \
 && echo "export PATH=$PATH:$JAVA_HOME/bin:/opt/scripts" >> /root/.bashrc
# Avoiding JVM delays caused by random number generation (remove if HWRNG or haveged is available)
RUN sed -i -e 's|securerandom.source=file:/dev/random|securerandom.source=file:/dev/urandom|' \
    $JAVA_HOME/lib/security/java.security

# Jetty into /opt/jetty. Then jetty9-dta-ssl-1.0.0.jar, logback, slf4j go into /opt/default/jetty-base
ENV jetty_version='9.3.24.v20180605'
WORKDIR /opt
RUN wget -nv -O jetty.zip "https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/${jetty_version}/jetty-distribution-${jetty_version}.zip" \
 && echo "40f4da905aaf7e1748dffc5b820bd1ec8a158390c48a4326a7610b1f37337bc4c0e30ba37e14ee89c7742fdb2c7247fafa7d21be26007bfc480e6a71078552e3  jetty.zip" | sha512sum -c - \
 && unzip -q jetty.zip \
 && ln -sf jetty-distribution-$jetty_version jetty \
 && rm -f jetty.zip \
 && cp /opt/jetty/bin/jetty.sh /etc/init.d/jetty
 COPY install/jetty-base /opt/default/jetty-base

RUN wget -nv https://build.shibboleth.net/nexus/content/repositories/releases/net/shibboleth/utilities/jetty9/jetty9-dta-ssl/1.0.0/jetty9-dta-ssl-1.0.0.jar \
 && echo "cb78f275833586ea052ee6f95b2bcf6d7b0f0dbb6916bbd00299d509c97b069662692fc95f4ff234b21d1e508e4b79c425de2cc003e13f5c87dd7738dc9d36b0  jetty9-dta-ssl-1.0.0.jar" | sha512sum -c - \
 && mkdir -p /opt/default/jetty-base/lib/ext \
 && cp -np jetty9-dta-ssl-1.0.0.jar /opt/default/jetty-base/lib/ext/

#RUN wget -nv -O logback.zip "http://logback.qos.ch/dist/logback-1.1.6.zip" \
# && unzip -q logback.zip \
# && ln -s logback-1.1.6 logback \
# && rm -f logback.zip \
# && mkdir -p /opt/default/jetty-base/lib/logging \
# && cd logback \
# &&   find . -name '*.jar' -delete \
# &&   cp -p logback-classic-1.1.6.jar logback-core-1.1.6.jar logback-access-1.1.6.jar /opt/default/jetty-base/lib/logging \
# && cd ..

RUN wget -nv -O slf4j.zip http://www.slf4j.org/dist/slf4j-1.7.18.zip \
 && unzip -q slf4j.zip \
 && rm -f slf4j.zip \
 && cd slf4j-1.7.18 \
 &&   mkdir -p /opt/default/jetty-base/lib/logging/ \
 &&   cp -p slf4j-api-1.7.18.jar /opt/default/jetty-base/lib/logging/ \
 && cd ..

# Shibboleth IDP
ENV PROD_VERSION='3.3.3'
ENV PROD_URL="https://shibboleth.net/downloads/identity-provider/${PROD_VERSION}/shibboleth-identity-provider-${PROD_VERSION}.zip"
ENV PROD_SHA512='602d256b00c5ec5c27008a762a7828ce8937d2c7b4d0375f48a359b1c97ebd2181a30cf0b7d450e7b70cbceb1b116463ae1a9a39628bc94622d7314c1b24ed70'
ENV PROD_ZIPFILE="shibboleth-identity-provider-${PROD_VERSION}.zip"
RUN wget -nv -O $PROD_ZIPFILE $PROD_URL \
 && echo "${PROD_SHA512} ${PROD_ZIPFILE}" | sha512sum -c - \
 && unzip -q ${PROD_ZIPFILE} \
 && ln -s "shibboleth-identity-provider-${PROD_VERSION}" shibboleth-idp-distribution \
 && rm -f ${PROD_ZIPFILE} \
 \
 && [[ -e "shibboleth-idp-distribution/messages/messages_de.properties" ]] || \
        wget -O shibboleth-idp-distribution/messages/messages_de.properties  \
  	    https://wiki.shibboleth.net/confluence/download/attachments/21660022/messages_de.properties


# The IdP status page depends on the JSP Standard Tag Library, which is not part of the distribution
RUN mkdir -p /opt/shibboleth-idp-distribution/edit-webapp/WEB-INF/lib \
 && cd /opt/shibboleth-idp-distribution/edit-webapp/WEB-INF/lib \
 && curl -O https://repo1.maven.org/maven2/jstl/jstl/1.2/jstl-1.2.jar
# To rebuild idp.war: use /rebuild_idp_war.sh in the container

COPY install/scripts/*.sh /scripts/
RUN chmod -R +x /scripts/*.sh
CMD ["/scripts/start.sh"]

ARG USERNAME=jetty
ARG UID=343007
RUN groupadd --gid $UID $USERNAME \
 && useradd --gid $UID --uid $UID $USERNAME \
 && chown $USERNAME:$USERNAME /run \
 && chown -R $USERNAME:$USERNAME /opt/default/jetty-base \
 && chown -R $USERNAME:$USERNAME /opt/shibboleth-idp-distribution

RUN mkdir -p /var/log/idp /var/log/jetty

VOLUME /etc/pki/shib-idp \
       /opt/jetty-base \
       /opt/shibboleth-idp \
       /var/log
       
EXPOSE 8080
USER $USERNAME
