#!/bin/sh

if [ "$KEYSTOREPW" == 'changeit' ]; then
    echo "Set KEYSTOREPW to a secret value before starting the IDP" && exit 1
fi

export JAVA_HOME=/opt/jre1.8.0
export JETTY_HOME=/opt/jetty/
export JETTY_BASE=/opt/jetty-base/
export PATH=$PATH:$JAVA_HOME/bin

/etc/init.d/jetty run
