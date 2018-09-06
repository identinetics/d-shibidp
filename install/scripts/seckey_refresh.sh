#!/bin/bash

IDP_HOME=/opt/shibboleth-idp

$IDP_HOME/bin/seckeygen.sh \
    --storefile $IDP_HOME/credentials/sealer.jks \
    --storepass $idp_sealer_storePassword \
    --versionfile $IDP_HOME/credentials/sealer.kver \
    --alias secret
