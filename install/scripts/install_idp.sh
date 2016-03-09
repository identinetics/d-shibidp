#!/bin/sh

cd /opt/shibboleth-idp-distribution/
bin/install.sh \
    -Didp.keystore.password=${KEYSTOREPW} \
    -Didp.sealer.password=${KEYSTOREPW} \
    -Didp.host.name=$IDP_FQDN

#chmod -R +r /opt/shibboleth-idp/
#cd /opt/shibboleth-idp/bin
#./build.sh init $IDP_FQDN metadata-gen
