#!/usr/bin/env bash

# data shared between containers goes via these definitions:
dockervol_root='/docker_volumes'
shareddata_root="${dockervol_root}/1shared_data"

# configure container
export IMGID='7'  # range from 2 .. 99; must be unique
export IMAGENAME="r2h2/shibidp${IMGID}"
export CONTAINERNAME="${IMGID}shibidp"
export CONTAINERUSER="jetty${IMGID}"  # group and user to run container
export CONTAINERUID="800${IMGID}"     # gid and uid for CONTAINERUSER
export ENTITYID='https://idp1.test.edu.portalverbund.at/idp.xml'
export IDP_FQDN='idp1.test.edu.portalverbund.at'
export KEYSTOREPW='changeit'
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
    -p 8443:8443
    -p 9443:9443
"
export VOLROOT="/docker_volumes/$CONTAINERNAME"  # container volumes on docker host
export VOLMAPPING="
    -v $VOLROOT/etc/pki/shib-idp/:/etc/pki/shib-idp/:Z
    -v $VOLROOT/opt/jetty-base/logs/:/opt/jetty-base/logs/:Z
    -v $VOLROOT/opt/shibboleth-idp/:/opt/shibboleth-idp/:Z
    -v $shareddata_root/md_feed:/opt/md_feed:ro
"
export STARTCMD='/start.sh'

# first create user/group/host directories if not existing
if ! id -u $CONTAINERUSER &>/dev/null; then
    groupadd -g $CONTAINERUID $CONTAINERUSER
    adduser -M -g $CONTAINERUID -u $CONTAINERUID $CONTAINERUSER
fi

# create dir with given user if not existing, relative to $HOSTVOLROOT; set/repair ownership
function chkdir {
    dir=$1
    user=$2
    mkdir -p "$VOLROOT/$dir"
    chown -R $user:$user "$VOLROOT/$dir"
}
chkdir opt/jetty-base/logs/ $CONTAINERUSER
chkdir /opt/shibboleth-idp/ $CONTAINERUSER
chkdir /etc/pki/shib-idp/ $CONTAINERUSER

