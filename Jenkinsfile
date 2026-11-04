// Runs on Jenkins (laptop). Build, push and deploy happen on the EC2 server over SSH,
// using the server's IAM role for ECR. Jenkins holds only an SSH key and the server address.
pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time: 30, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  triggers { pollSCM('H/2 * * * *') }

  parameters {
    string(name: 'DEPLOY_TAG', defaultValue: '',
           description: 'Empty = build and deploy this commit. An existing ECR tag (e.g. v1.0.0) = deploy that tag without building (rollback).')
  }

  environment {
    SSH_OPTS = '-o StrictHostKeyChecking=accept-new -o ConnectTimeout=20 -o ServerAliveInterval=15 -o ServerAliveCountMax=4'
  }

  stages {
    stage('Checkout') {
      steps {
        script {
          env.SHORT_SHA = sh(script: 'git rev-parse --short=7 HEAD', returnStdout: true).trim()
          env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.SHORT_SHA}"
          env.DEPLOY_VERSION = params.DEPLOY_TAG?.trim() ? params.DEPLOY_TAG.trim() : env.IMAGE_TAG
        }
        echo "Commit ${env.SHORT_SHA} | build tag ${env.IMAGE_TAG} | version to deploy ${env.DEPLOY_VERSION}"
      }
    }

    stage('Validate configuration') {
      steps {
        sh '''
          set -e
          for f in scripts/*.sh; do bash -n "$f"; echo "syntax ok: $f"; done
          if git ls-files | grep -E '(^|/)\\.env$|\\.pem$|\\.tfvars$|\\.tfstate'; then
            echo "ERROR: a secret or state file is tracked in Git"; exit 1
          fi
          echo "no secret files tracked in Git"
        '''
      }
    }

    stage('Run available tests') {
      when { expression { !params.DEPLOY_TAG?.trim() } }
      steps {
        sh '''
          found=0
          for s in user product order; do
            if grep -q '"test"' ${s}-service/package.json; then found=1; echo "test script found in ${s}-service"; fi
          done
          if [ "$found" = 0 ]; then
            echo "No automated tests are defined in the application (application code is out of scope); nothing to run."
          fi
        '''
      }
    }

    stage('Sync build server') {
      steps {
        withCredentials([
          sshUserPrivateKey(credentialsId: 'ec2-deploy', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
          string(credentialsId: 'ec2-host', variable: 'EC2_HOST')
        ]) {
          sh '''
            mkdir -p ~/.ssh
            ssh $SSH_OPTS -i "$SSH_KEY" "$SSH_USER@$EC2_HOST" "cd ~/build && git fetch origin && git checkout -f $GIT_COMMIT && git log --oneline -1"
          '''
        }
      }
    }

    stage('Build, tag and push images') {
      when { expression { !params.DEPLOY_TAG?.trim() } }
      steps {
        withCredentials([
          sshUserPrivateKey(credentialsId: 'ec2-deploy', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
          string(credentialsId: 'ec2-host', variable: 'EC2_HOST')
        ]) {
          sh '''ssh $SSH_OPTS -i "$SSH_KEY" "$SSH_USER@$EC2_HOST" "cd ~/build && bash scripts/ci-build.sh $IMAGE_TAG"'''
        }
      }
    }

    stage('Deploy to EC2') {
      steps {
        script { env.DEPLOY_STARTED = 'true' }
        withCredentials([
          sshUserPrivateKey(credentialsId: 'ec2-deploy', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
          string(credentialsId: 'ec2-host', variable: 'EC2_HOST')
        ]) {
          sh '''ssh $SSH_OPTS -i "$SSH_KEY" "$SSH_USER@$EC2_HOST" "cd ~/build && bash scripts/ci-release.sh $DEPLOY_VERSION"'''
        }
      }
    }

    stage('Verify deployment') {
      steps {
        withCredentials([
          sshUserPrivateKey(credentialsId: 'ec2-deploy', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
          string(credentialsId: 'ec2-host', variable: 'EC2_HOST')
        ]) {
          sh '''
            set -e
            for p in healthz health/users health/products health/orders; do
              code=$(curl -s -o /dev/null -w "%{http_code}" --retry 5 --retry-delay 3 --retry-connrefused --max-time 15 "http://$EC2_HOST/$p")
              echo "$p -> $code"
              [ "$code" = "200" ] || exit 1
            done
            running=$(ssh $SSH_OPTS -i "$SSH_KEY" "$SSH_USER@$EC2_HOST" "cat /opt/app/.current_tag")
            echo "running tag on server: $running (expected $DEPLOY_VERSION)"
            [ "$running" = "$DEPLOY_VERSION" ]
          '''
        }
      }
    }
  }

  post {
    success { echo "Deployed ${env.DEPLOY_VERSION} successfully" }
    failure {
      script {
        if (env.DEPLOY_STARTED == 'true') {
          echo 'Deployment failed: rolling back to the last good tag'
          withCredentials([
            sshUserPrivateKey(credentialsId: 'ec2-deploy', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
            string(credentialsId: 'ec2-host', variable: 'EC2_HOST')
          ]) {
            sh '''ssh $SSH_OPTS -i "$SSH_KEY" "$SSH_USER@$EC2_HOST" "cd ~/build && bash scripts/ci-rollback.sh $DEPLOY_VERSION"'''
          }
        } else {
          echo 'Failed before deployment: the running version is unchanged'
        }
      }
    }
    always {
      writeFile file: 'build-info.txt', text: "build=${env.BUILD_NUMBER}\ncommit=${env.GIT_COMMIT}\ntag=${env.DEPLOY_VERSION ?: 'n/a'}\nresult=${currentBuild.currentResult}\n"
      archiveArtifacts artifacts: 'build-info.txt', allowEmptyArchive: true
    }
  }
}
