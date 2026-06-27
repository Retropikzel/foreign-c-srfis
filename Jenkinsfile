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

    environment {
        R7RS_SCHEMES="capyscheme chibi chicken gauche kawa mosh racket sagittarius stklos ypsilon"
        R6RS_SCHEMES="chezscheme guile ikarus ironscheme mosh racket sagittarius ypsilon"
        SRFIS="170"
    }

    stages {
        stage('x86_64 Debian') {
            steps {
                script {
                    env.SRFIS.split().each { SRFI ->
                        env.R6RS_SCHEMES.split().each { SCHEME ->
                            stage("${SCHEME} ${SRFI}") {
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    sh "make SCHEME=${SCHEME} SRFI=${SRFI} RNRS=r6rs run-test-docker"
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
                    env.SRFIS.split().each { SRFI ->
                        env.R7RS_SCHEMES.split().each { SCHEME ->
                            stage("${SCHEME} ${SRFI}") {
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    sh "make SCHEME=${SCHEME} SRFI=${SRFI} RNRS=r6rs run-test-docker"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
