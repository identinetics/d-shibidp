#!/usr/bin/env bash

# Initialize and update the docker build environment
# Providing resources before starting docker build provides better control about updates
# and can speed up the build process.

update_pkg="False"

while getopts ":huU" opt; do
  case $opt in
    u)
      update_pkg="True"
      ;;
    U)
      update_pkg="False"
      ;;
    *)
      echo "usage: $0 [-u] [-U]
   -u  update git repos in docker build context
   -U  do not update git repos in docker build context (default)

   To update packages delivered as tar-balls just delete them from install/opt
   "
      exit 0
      ;;
  esac
done

shift $((OPTIND-1))


BUILDDIR=$(cd $(dirname $BASH_SOURCE[0]) && pwd)
source $BUILDDIR/dscripts/conf_lib.sh  # load library functions
cd $BUILDDIR


# download and verify components to be installed with docker build
mkdir -p install/downloads
cd install/downloads
# JAVA JRE 1.8.0 Update 121
if [ ! -e "jre1.8.0" ]; then
    JRE_CHECKSUM="30bf5fbac0cfbc9201cac1d6973dbc96e5f55043ab315eda8c7aeb23df4f2644  jre-linux-x64.tar.gz"
    wget -qO- --no-cookies --no-check-certificate -O jre-linux-x64.tar.gz \
        --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
        "http://download.oracle.com/otn-pub/java/jdk/8u121-b13/e9e7ea248e2c4826b92b3f075a80e441/jre-8u121-linux-x64.tar.gz"
    rm -rf jre1.8.0_*
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

# Download Shibboleth IDP
PROD_VERSION='3.3.0'
PROD_URL="https://shibboleth.net/downloads/identity-provider/latest/shibboleth-identity-provider-$PROD_VERSION.zip"
PROD_SHA256='a0dd96ad8770539b6f1249f7cea98b944cff846b4831892e8deee62b91b60277'
PROD_ZIPFILE="shibboleth-identity-provider-$PROD_VERSION.zip"
PROD_INSTDIR='shibboleth-idp-distribution'
get_from_ziparchive_with_checksum $PROD_URL $PROD_ZIPFILE $PROD_SHA256 $PROD_VERSION


if [ ! -e "shibboleth-idp-distribution/messages/messages_de.properties" ]; then
	wget -O shibboleth-idp-distribution/messages/messages_de.properties \
	    https://wiki.shibboleth.net/confluence/download/attachments/21660022/messages_de.properties
fi
cd ../..