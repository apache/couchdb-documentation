pipeline {

  agent none

  environment {
    GIT_COMMITTER_NAME = 'Jenkins User'
    GIT_COMMITTER_EMAIL = 'couchdb@apache.org'
    DOCKER_IMAGE = 'couchdbdev/debian-buster-erlang-all:latest'
    DOCKER_ARGS = '-e npm_config_cache=npm-cache -e HOME=. -v=/etc/passwd:/etc/passwd -v /etc/group:/etc/group'
  }

  options {
    buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '10'))
    // This fails the build immediately if any parallel step fails
    parallelsAlwaysFailFast()
    preserveStashes(buildCount: 10)
    timeout(time: 30, unit: 'MINUTES')
    timestamps()
  }

  stages {
    stage('Test') {
      matrix {
        axes {
          axis {
            name 'TARGET'
            values "html", "man", "check"
          }
        }
        stages {
          stage('Test') {
            agent {
              docker {
                image "${DOCKER_IMAGE}"
                label 'docker'
                args "${DOCKER_ARGS}"
              }
            }
            options {
              timeout(time: 90, unit: 'MINUTES')
            }
            steps {
              sh '''
                make ${TARGET}
              '''
            }
            post {
              cleanup {
                // UGH see https://issues.jenkins-ci.org/browse/JENKINS-41894
                sh 'rm -rf ${WORKSPACE}/*'
              }
            }
          } // stage
        } // stages
      } // matrix
    } // stage "Test"
  } // stages
} // pipeline
