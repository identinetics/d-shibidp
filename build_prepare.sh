#!/usr/bin/env bash

# download and verify components to be installed with docker build
mkdir -p install/downloads
cd install/downloads
# JAVA JRE 1.8.0 Update 102
JRE_DOWNLOAD_URL='http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jre-8u102-linux-x64.tar.gz'
JRE_CHECKSUM='214ff6b52f5b1bccfc139dca910cea25f6fa19b9b96b4e3c10e699cd3e780dfb  jre-linux-x64.tar.gz'
if [ ! -e "jre1.8.0" ]; then
    rm -rf jre1.8.0_*
    wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
        -O jre-linux-x64.tar.gz $JRE_DOWNLOAD_URL
    echo $JRE_CHECKSUM | sha256sum -c -
    tar -xzf jre-linux-x64.tar.gz
    rm jre-linux-x64.tar.gz
    ln -sf jre1.8.0_* jre1.8.0
fi
if [ ! -e "jetty" ]; then
    # download jetty int ./jetty. Then jetty9-dta-ssl-1.0.0.jar, logback, slf4j go into jetty-base
    jetty_version='9.3.3.v20150827'
    wget -O jetty.zip \
        "https://eclipse.org/downloads/download.php?file=/jetty/$jetty_version/dist/jetty-distribution-$jetty_version.zip&r=1"
    echo "f281590d3fcde0f9a8fce0691aa1a1a838d3666a49474f9c8bc01a5468ef50818358233bcb958b2cb434b097c9d0ccda626616fb4731c5754b13f0740f76f1f5  jetty.zip" | sha512sum -c -
    unzip -q jetty.zip
    ln -sf jetty-distribution-$jetty_version jetty
    rm jetty.zip

    wget https://build.shibboleth.net/nexus/content/repositories/releases/net/shibboleth/utilities/jetty9/jetty9-dta-ssl/1.0.0/jetty9-dta-ssl-1.0.0.jar
    echo "cb78f275833586ea052ee6f95b2bcf6d7b0f0dbb6916bbd00299d509c97b069662692fc95f4ff234b21d1e508e4b79c425de2cc003e13f5c87dd7738dc9d36b0  jetty9-dta-ssl-1.0.0.jar" | sha512sum -c -
    mkdir -p ../jetty-base/lib/ext
    cp -p jetty9-dta-ssl-1.0.0.jar ../jetty-base/lib/ext/

    wget -O logback.zip "http://logback.qos.ch/dist/logback-1.1.6.zip"
    unzip logback.zip
    ln -s logback-1.1.6 logback
    rm logback.zip
    mkdir -p ../jetty-base/lib/logging
    cd logback
        find . -name '*.jar' -delete
        cp -p logback-classic-1.1.6.jar logback-core-1.1.6.jar logback-access-1.1.6.jar ../../jetty-base/lib/logging
    cd ..

    wget -O slf4j.zip http://www.slf4j.org/dist/slf4j-1.7.18.zip
    unzip slf4j.zip
    rm slf4j.zip
    cd slf4j-1.7.18
        cp -p slf4j-api-1.7.18.jar ../../jetty-base/lib/logging/
    cd ..
fi
 if [ ! -e "shibboleth-idp-distribution" ]; then
     wget -O shibboleth-identity-provider.zip \
         "https://shibboleth.net/downloads/identity-provider/3.2.1/shibboleth-identity-provider-3.2.1.zip"
     echo "5b4e10afb5af2bd02fb16261c34fef8da5b47dabd501de101f00e88529eec2cf25b3518c4d865027820e66ab52730310b01dff7f223cb53194b48fe89ade0954  shibboleth-identity-provider.zip" | sha512sum -c -
     unzip -q shibboleth-identity-provider.zip
     rm shibboleth-identity-provider.zip
     ln -sf shibboleth-identity-provider-3.2.1 shibboleth-idp-distribution
 fi

cd ../..