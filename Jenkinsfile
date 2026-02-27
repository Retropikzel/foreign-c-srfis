pipeline {
    agent {
        dockerfile {
            filename 'Dockerfile.jenkins'
            label 'docker-x86_64'
            args '--user=root --privileged -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '10'))
    }

    parameters {
        string(name: 'R7RS_SCHEMES', defaultValue: 'chibi chicken gauche guile kawa mosh racket sagittarius stklos ypsilon', description: '')
        string(name: 'R6RS_SCHEMES', defaultValue: 'chezscheme guile ikarus ironscheme mosh racket sagittarius ypsilon', description: '')
        string(name: 'SRFIS', defaultValue: '106 170', description: '')
    }

    stages {
        stage('Tests') {
            stage('R6RS x86_64 Debian') {
                steps {
                    script {
                        params.SRFIS.split().each { SRFI ->
                            params.R6RS_SCHEMES.split().each { SCHEME ->
                                stage("${SCHEME} - ${SRFI}") {
                                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                        sh "timeout 600 make SCHEME=${SCHEME} SRFI=${SRFI} RNRS=r6rs run-test-docker"
                                    }
                                }
                            }
                        }
                    }
                }
            }
            stage('R7RS x86_64 Debian') {
                steps {
                    script {
                        params.SRFIS.split().each { SRFI ->
                            params.R7RS_SCHEMES.split().each { SCHEME ->
                                stage("${SCHEME} - ${SRFI}") {
                                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                        sh "timeout 600 make SCHEME=${SCHEME} SRFI=${SRFI} RNRS=r6rs run-test-docker"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
