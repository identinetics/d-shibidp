pipeline {
    agent any
    options { disableConcurrentBuilds() }
    parameters {
        string(defaultValue: 'True', description: '"True": initial cleanup: remove container and volumes; otherwise leave empty', name: 'start_clean')
        string(description: '"True": "Set --nocache for docker build; otherwise leave empty', name: 'nocache')
        string(description: '"True": push docker image after build; otherwise leave empty', name: 'pushimage')
        string(description: '"True": keep running after test; otherwise leave empty to delete container and volumes', name: 'keep_running')
 }

    stages {
        stage('Cleanup ') {
            when {
                expression { params.$start_clean?.trim() != '' }
            }
            steps {
                sh '''
                    docker-compose -f dc.yaml down -v 2>/dev/null | true
                '''
            }
        }
        stage('Build') {
            steps {
                sh '''
                    [[ "$nocache" ]] && nocacheopt='-c' && echo 'build with option nocache'
                    export MANIFEST_SCOPE='local'
                    export PROJ_HOME='.'
                    ./dcshell/build -f dc.yaml $nocacheopt
                    echo "=== build completed with rc $?"
                '''
            }
        }
        stage('Run') {
            steps {
                sh '''#!/bin/bash -xv
                    # docker-compose -f dc.yaml up --no-start  ## future docker version
                    docker-compose -f dc.yaml run --rm --name shibidp_init shibidp tail -f /dev/null &
                    echo 'initializing config to persistent volumes'
                    sleep 2
                    docker cp install/test/config/etc/pki/shib-idp shibidp_init:/etc/pki/
                    docker cp install/test/config/opt/jetty-base shibidp_init:/opt/
                    docker cp install/test/config/opt/shibboleth-idp shibidp_init:/opt/
                    docker rm -f shibidp_init
                    docker-compose -f dc.yaml up -d
                    docker-compose -f dc.yaml exec -T shibidp /scripts/status.sh
                    docker-compose -f dc.yaml logs shibidp
                '''
            }
        }
       stage('Push ') {
            when {
                expression { params.pushimage?.trim() != '' }
            }
            steps {
                sh '''
                    default_registry=$(docker info 2> /dev/null |egrep '^Registry' | awk '{print $2}')
                    echo "  Docker default registry: $default_registry"
                    export MANIFEST_SCOPE='local'
                    export PROJ_HOME='.'
                    ./dcshell/build -f dc.yaml -P
                '''
            }
        }
    }
    post {
        always {
            sh '''
                if [[ "$keep_running" ]]; then
                    echo "Keep container running"
                else
                    echo 'Remove container, volumes'
                    docker-compose -f dc.yaml rm --force -v shibidp 2>/dev/null || true
                fi
            '''
        }
    }
}