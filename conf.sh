#!/usr/bin/env bash
set -x

# configure container
export IMGID='7'  # range from 2 .. 99; must be unique
export IMAGENAME="r2h2/shibidp${IMGID}"
export CONTAINERNAME="${IMGID}shibidp"
export CONTAINERUSER="jetty${IMGID}"  # group and user to run container
export CONTAINERUID="800${IMGID}"     # gid and uid for CONTAINERUSER
export ENTITYID='https://idp1.test.wpv.portalverbund.at/idp.xml'
export IDP_FQDN='idp1.test.wpv.portalverbund.at'
export KEYSTOREPW='changeit'
export JAVA_UPDATE_VERSION=60
export JAVA_VERSION=1.8.0_${JAVA_UPDATE_VERSION}
export BUILDARGS="
    --build-arg USERNAME=$CONTAINERUSER \
    --build-arg UID=$CONTAINERUID \
"
export ENVSETTINGS="
    -e ENTITYID=$ENTITYID
    -e IDP_FQDN=$IDP_FQDN
    -e KEYSTOREPW=$KEYSTOREPW
"
export NETWORKSETTINGS="
    --net http_proxy
    --ip 10.1.1.${IMGID}
"
export VOLROOT="/docker_volumes/$CONTAINERNAME"  # container volumes on docker host
export VOLMAPPING="
    -v $VOLROOT/opt/shibboleth-idp/:/opt/shibboleth-idp/:Z
    -v $VOLROOT/etc/pki/shib-idp/:/etc/pki/shib-idp/:Z
"
export STARTCMD='/scripts/start.sh'

# first create user/group/host directories if not existing
if ! id -u $CONTAINERUSER &>/dev/null; then
    groupadd -g $CONTAINERUID $CONTAINERUSER
    adduser -M -g $CONTAINERUID -u $CONTAINERUID $CONTAINERUSER
fi
if [ -d $VOLROOT/var/log/$CONTAINERNAME ]; then
    mkdir -p $VOLROOT/var/log
    chown $CONTAINERUSER:$CONTAINERUSER $VOLROOT/var/log
fi
# create dir with given user if not existing, relative to $HOSTVOLROOT; set/repair ownership
function chkdir {
    dir=$1
    user=$2
    mkdir -p "$VOLROOT/$dir"
    chown -R $user:$user "$VOLROOT/$dir"
}
chkdir /opt/shibboleth-idp/ $CONTAINERUSER
chkdir /etc/pki/shib-idp/ $CONTAINERUSER


# download and verify components to be installed with docker build
mkdir -p install/downloads
cd install/downloads
if [ ! -d "jre1.8.0" ]; then
    wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
        -O jre-linux-x64.tar.gz \
        http://download.oracle.com/otn-pub/java/jdk/8u${JAVA_UPDATE_VERSION}-b27/jre-8u${JAVA_UPDATE_VERSION}-linux-x64.tar.gz
    echo "49dadecd043152b3b448288a35a4ee6f3845ce6395734bacc1eae340dff3cbf5  jre-linux-x64.tar.gz" | sha256sum -c -
    tar -xzf jre-linux-x64.tar.gz
    rm jre-linux-x64.tar.gz
    ln -s jre1.8.0_${JAVA_UPDATE_VERSION} jre1.8.0
fi
if [ ! -d "jetty" ]; then
    # download jetty int ./jetty. Then jetty9-dta-ssl-1.0.0.jar, logback, slf4j go into jetty-base
    jetty_version='9.3.3.v20150827'
    wget -O jetty.zip \
        "https://eclipse.org/downloads/download.php?file=/jetty/$jetty_version/dist/jetty-distribution-$jetty_version.zip&r=1"
    echo "f281590d3fcde0f9a8fce0691aa1a1a838d3666a49474f9c8bc01a5468ef50818358233bcb958b2cb434b097c9d0ccda626616fb4731c5754b13f0740f76f1f5  jetty.zip" | sha512sum -c -
    unzip -q jetty.zip
    ln -s jetty-distribution-$jetty_version jetty
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
        ls | grep -v .jar | xargs rm -rf
        cp -p logback-classic-1.1.6.jar logback-core-1.1.6.jar logback-access-1.1.6.jar ../../jetty-base/lib/logging
    cd ..

    wget -O slf4j.zip http://www.slf4j.org/dist/slf4j-1.7.18.zip
    unzip slf4j.zip
    rm slf4j.zip
    cd slf4j-1.7.18
        ls | grep -v slf4j-api-1.7.18.jar | xargs rm -rf
        cp -p slf4j-api-1.7.18.jar ../../jetty-base/lib/logging/
    cd ..
fi
if [ ! -e "shibboleth-idp-distribution" ]; then
    wget -O shibboleth-identity-provider.zip \
        "https://shibboleth.net/downloads/identity-provider/3.2.1/shibboleth-identity-provider-3.2.1.zip"
    echo "5b4e10afb5af2bd02fb16261c34fef8da5b47dabd501de101f00e88529eec2cf25b3518c4d865027820e66ab52730310b01dff7f223cb53194b48fe89ade0954  shibboleth-identity-provider.zip" | sha512sum -c -
    unzip -q shibboleth-identity-provider.zip
    rm shibboleth-identity-provider.zip
    ln -s shibboleth-identity-provider-3.2.1 shibboleth-idp-distribution
fi

cd ../..