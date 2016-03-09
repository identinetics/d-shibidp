#!/bin/sh

export JAVA_HOME=/opt/jre1.8.0
export JETTY_HOME=/opt/jetty/
export JETTY_BASE=/opt/jetty-base/
export PATH=$PATH:$JAVA_HOME/bin

/etc/init.d/jetty run
