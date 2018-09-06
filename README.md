# Shibboleth IDP V3 docker image

## Overview 
This Docker image contains a deployed Shibboleth IdP 3 running on Java 8 JRE  and Jetty 9.3.3 
running on the latest CentOS 7 base. Buld + run with docker-compose



## Configure & run
 
    
    
    # run the IDP's install script (keep the defaults for the source and installation directories)
    # this will throw away the container, but the config files are kept on the docker host
    docker-compose -f dc.yaml run --rm /opt/scripts/install_idp.sh  

    # now configure /opt/jetty-base and /etc/shibboleth-idp
    . use idp.home/metadata/idp-metadata.xml to create a reasonable metadata file and upload it to the metadata feed
    . configure the metadata provider (local via file system or well-know location URL)
    . configure jetty certificates (jetty-base/start.d/ssl.ini, backchannel.ini)  
    . attribute-filter, -resolver; idp.properites; ldap.properties 
    . optional: redirect logfiles to /var/log: see logback.xml (both jetty and shib-idp
    . if running with a reverse proxy (load balancer) fronting the IDP you need to tell jetty to
      activate the ForwardedRequestCustomize class (see example install/jetty-base/etc/jetty.xml)
    . optionally copy jstl-1.2.jar to /opt/shibboleth-idp/edit-webapp/WEB-INF/lib (-> for idp/status page)

    # start jetty
    docker-compose -f dc.yaml run --rm shibidp bash 
 
    # To effect changes to the idp.war file:
    docker-compose -f dc.yaml run --rm shibidp /scripts/rebuild_idp_war.sh
    
    # test attribute release for user 'eid-test'
    curl 'http://localhost:8080/idp/profile/admin/resolvertest?principal=eid-test&requester=https%3A%2F%2Fsp.example.org%2Fsp'

## Other Entrypoints

    /scripts/create_idp_cert.sh   # create a new singing and/or encryption certificate
    /scripts/seckey_init.sh       # create a new data sealer keystore (e.g. after copying config form other deployment)
    /scripts/seckey_refresh.sh    # call daily to create a new data sealer key 

## Upgrade to new version of Shibboleth, Jetty and/or Oracle JRE

* Update Dockerfile Oracle Java ENV variables
* build

## References

* https://github.com/rhoerbe/docker-template
* https://github.com/jtgasper3/docker-shibboleth-idp
* https://wiki.shibboleth.net/confluence/display/IDP30/Jetty93

