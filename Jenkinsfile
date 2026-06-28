pipeline {
    agent {
        dockerfile {
            filename 'Dockerfile.jenkins'
            label 'docker-x86_64'
            args '--user=root --privileged -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    triggers {
        GenericTrigger(
         genericVariables: [
          [key: 'ref', value: '$.ref']
         ],

         causeString: 'Triggered on $ref',

         printContributedVariables: true,
         printPostContent: true,

         silentResponse: false,
         shouldNotFlatten: false,

         regexpFilterText: '$ref',
         regexpFilterExpression: 'refs/heads/' + BRANCH_NAME
        )
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
        stage('R6RS Debian') {
            steps {
                script {
                    env.SRFIS.split().each { SRFI ->
                        env.R6RS_SCHEMES.split().each { SCHEME ->
                            stage("${SCHEME} ${SRFI}") {
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    sh "make SCHEME=${SCHEME} SRFI=${SRFI} RNRS=r6rs test-docker"
                                }
                            }
                        }
                    }
                }
            }
        }
        stage('R7RS Debian') {
            steps {
                script {
                    env.SRFIS.split().each { SRFI ->
                        env.R7RS_SCHEMES.split().each { SCHEME ->
                            stage("${SCHEME} ${SRFI}") {
                                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                                    sh "make SCHEME=${SCHEME} SRFI=${SRFI} RNRS=r7rs test-docker"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
