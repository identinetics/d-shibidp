#!/usr/bin/env bash

# Create an X.509 cert to be used for signing and/or encrpytion

cd /opt/shibboleth-idp/credentials

java -cp "../webapp/WEB-INF/lib/*:../bin/lib/*" \
  net.shibboleth.utilities.java.support.security.SelfSignedCertificateGenerator \
  --lifetime 5 \
  --certfile idp.crt.new \
  --keyfile idp.key.new \
  --hostname $IDP_FQDN \
  --uriAltName $ENTITYID

