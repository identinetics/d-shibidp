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
                sh '''
                    docker-compose -f dc.yaml up --no-start
                    docker cp install/test/config/etc.pki.shib-idp shibidp:/etc/pki/shib-idp
                    docker cp install/test/config/opt.jetty-base shibidp:/opt/jetty-base
                    docker cp install/test/config/opt-shibboleth-idp shibidp:/opt/shibboleth-idp
                    docker-compose -f dc.yaml down
                    docker-compose -f dc.yaml exec -T shibidp /scripts/status.sh
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