# Shibboleth IDP V3 docker image

## Overview 
This Docker image contains a deployed Shibboleth IdP 3 running on Java Runtime 1.8 and Jetty 9.3.3 
running on the latest CentOS 7 base.

- Following the recommendations of the shibboleth.net wiki
- Docker project structure conforming to rhoerbe/docker-template (matching host with guest uids, ..)
- No configuration data inside the container (but via conf*.sh)
- Software components are downloaded before the build step in conf.sh (e.g. to change to an 
  internal repo) - except some utilities from centos repo
- Shib-idp installation happens past image building
- Volume mount points for config, logs etc. are in standard locations
- This image is not being used for production (yet)


## Build the docker image
1. copy conf.sh.default to conf.sh (or confN.sh, where n is the container number)
2. adopt conf*.sh
3. run build.sh  # this will also create the host directories to be munted in the container


## Configure & run
 
    run.sh -h  # print usage
    
    # run the IDP's install script (keep the defaults for the source and installation directories)
    # this will throw away the container, but the config files are kept on the docker host
    run.sh -i /opt/scripts/install_idp.sh  

    # now configure /opt/jetty-base and /etc/shibboleth-idp
    . use idp.home/metadata/idp-metadata.xml to create a reasonable metadata file and upload it to the metadata feed
    . configure the metadata provider
    . configure jetty certificates (jetty-base/start.d/ssl.ini, backchannel.ini)  
    . optional: redirect logfiles to /var/log: see logback.xml (both jetty and shib-idp)

    # start jetty
    run.sh     
 


## References

* https://github.com/rhoerbe/docker-template
* https://github.com/jtgasper3/docker-shibboleth-idp
* https://wiki.shibboleth.net/confluence/display/IDP30/Jetty93

