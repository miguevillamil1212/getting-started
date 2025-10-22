pipeline {
  agent any
  environment {
    DOCKERHUB_CREDENTIALS = 'docker-hub-credentials'     // tu credencial en Jenkins
    IMAGE_REPO            = 'miguel1212/parcial2-python'  // cambia si usas otro repo
    APP_NAME              = 'parcial2-python'
    APP_PORT              = '5000'   // Flask
    HOST_PORT             = '5000'
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Build') {
      steps {
        script {
          def SHORT = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
          env.IMG_SHA    = "${env.IMAGE_REPO}:${SHORT}"
          env.IMG_LATEST = "${env.IMAGE_REPO}:latest"
          sh """
            set -eux
            docker build -t ${IMG_SHA} -t ${IMG_LATEST} .
          """
        }
      }
    }
    stage('Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDENTIALS, usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh """
            set -eux
            echo "\$DH_PASS" | docker login -u "\$DH_USER" --password-stdin
            docker push ${IMG_SHA}
            docker push ${IMG_LATEST}
          """
        }
      }
    }
    stage('Deploy') {
      when { branch 'main' }
      steps {
        sh """
          set -eux
          docker rm -f ${APP_NAME} || true
          docker pull ${IMG_LATEST}
          docker run -d --name ${APP_NAME} -p ${HOST_PORT}:${APP_PORT} ${IMG_LATEST}
        """
      }
    }
  }
  post {
    success { echo "✅ OK: ${env.IMG_LATEST}" }
    failure { echo "❌ Falló. Si el error es 'permission denied /var/run/docker.sock', es del host, no del Jenkinsfile." }
  }
}
