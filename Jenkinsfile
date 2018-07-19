// requires python3 + pyyaml + jinja2
pipeline {
    agent any
    options { disableConcurrentBuilds() }
    parameters {
        string(defaultValue: 'True', description: '"True": initial cleanup: remove container and volumes; otherwise leave empty', name: 'start_clean')
        string(defaultValue: '', description: '"True": "Set --nocache for docker build; otherwise leave empty', name: 'nocache')
        string(defaultValue: '', description: '"True": push docker image after build; otherwise leave empty', name: 'pushimage')
        string(defaultValue: '', description: '"True": keep running after test; otherwise leave empty to delete container and volumes', name: 'keep_running')
        string(defaultValue: '', description: '"True": overwrite default docker registry user; otherwise leave empty', name: 'docker_registry_user')
        string(defaultValue: '', description: '"True": overwrite default docker registry host; otherwise leave empty', name: 'docker_registry_host')
    }

    stages {
        stage('Build') {
            steps {
                echo "==========================="
                sh 'set +x; source ./conf.sh; echo "Building $IMAGENAME"'
                echo "Pipeline args: nocache=$nocache; pushimage=$pushimage; docker_registry_user=$docker_registry_user; docker_registry_host=$docker_registry_host"
                echo "==========================="
                withDockerRegistry([ credentialsId: "DockerRepoUpload", url: "$docker_registry_host" ]) {
                    sh '''
                        set +x
                        echo [[ "$docker_registry_user" ]] && echo "DOCKER_REGISTRY_USER $docker_registry_user"  > local.conf
                        echo [[ "$docker_registry_host" ]] && echo "DOCKER_REGISTRY_HOST $docker_registry_host"  >> local.conf
                        [[ "$pushimage" ]] && pushopt='-Pl'
                        [[ "$nocache" ]] && nocacheopt='-c'
                        ./dscripts/build.sh -p $nocacheopt $pushopt
                    '''
                sh '''
                    echo "generate run script"
                    ./dscripts/run.sh -w
                    echo "create docker-compose-setup.yaml"
                    dscripts/gen_compose_yaml.sh -C docker-compose-setup.template
                    mv work/docker-compose.yaml docker-compose-setup.yaml
                    echo "create docker-compose.yaml"
                    dscripts/gen_compose_yaml.sh
                    mv work/docker-compose.yaml .
                '''
            }
        }
        stage('Cleanup container, volumes') {
            steps {
                sh '''
                    rm conf.sh 2> /dev/null || true
                    ln -sf conf.sh.default conf.sh
                    if [[ "$start_clean" ]]; then
                        docker-compose down --volumes
                    fi
                '''
            }
        }
        stage('Setup + Run') {
            steps {
                sh '''#!/bin/bash
                    >&2 echo "setup test config"
                    docker-compose -f docker-compose-setup.yaml run --rm shibsp \
                        cp /opt/install/config/express_setup_citest.yaml /opt/etc/express_setup_citest.yaml
                    docker-compose -f docker-compose-setup.yaml run --rm shibsp \
                        /opt/install/scripts/express_setup.sh -s express_setup_citest.yaml
                    >&2 echo "start server"
                    docker-compose up -d
                    sleep 2
                    docker-compose logs shibsp
                '''
            }
        }
        stage('Test') {
            steps {
                sh '''
                    sleep 1
                    docker-compose exec -T shibidp /status.sh
                '''
            }
        }
    }
    post {
        always {
            sh '''
                if [[ "$keep_running" ]]; then
                    echo 'Keep container running'
                else
                    echo 'removing docker volumes and container'
                    docker-compose down --volumes 2>/dev/null || true
                fi
            '''
        }
    }
}