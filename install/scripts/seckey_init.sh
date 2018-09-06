#!/usr/bin/env bash

# create a new keystore for data sealer
# (useful if config data was copied from another deployment)

cd /opt/shibboleth-idp/credentials/
rm -f sealer.jks
/opt/shibboleth-idp/bin/seckeygen.sh --storefile sealer.jks --alias secret \
    --storepass $idp_sealer_storePassword \
    --versionfile sealer.kver

keytool -v -list -keystore sealer.jks -storetype JCEKS \
    -storepass $idp_sealer_storePassword
