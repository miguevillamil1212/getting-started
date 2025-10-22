pipeline {
  agent any

  environment {
    DOCKERHUB_CREDENTIALS = 'docker-hub-credentials'   // <-- tu credencial de Docker Hub
    IMAGE_REPO            = 'miguel1212/parcial2-python' // <-- cambia si usas otro repo
    APP_NAME              = 'parcial2-python'
    APP_PORT              = '5000'    // puerto interno Flask
    HOST_PORT             = '5000'    // puerto expuesto en el host Jenkins
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build') {
      steps {
        script {
          def SHORT = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
          env.IMAGE_TAG_SHA    = "${env.IMAGE_REPO}:${SHORT}"
          env.IMAGE_TAG_LATEST = "${env.IMAGE_REPO}:latest"

          sh """
            set -eux
            docker build -t ${IMAGE_TAG_SHA} -t ${IMAGE_TAG_LATEST} .
          """
        }
      }
    }

    stage('Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: env.DOCKERHUB_CREDENTIALS,
          usernameVariable: 'DH_USER',
          passwordVariable: 'DH_PASS'
        )]) {
          sh """
            set -eux
            echo "\$DH_PASS" | docker login -u "\$DH_USER" --password-stdin
            docker push ${IMAGE_TAG_SHA}
            docker push ${IMAGE_TAG_LATEST}
          """
        }
      }
    }

    stage('Deploy') {
      when { branch 'main' } // despliega solo en main
      steps {
        sh """
          set -eux
          docker rm -f ${APP_NAME} || true
          docker pull ${IMAGE_TAG_LATEST}
          docker run -d --name ${APP_NAME} -p ${HOST_PORT}:${APP_PORT} ${IMAGE_TAG_LATEST}
        """
      }
    }
  }

  post {
    success { echo "✅ OK: ${env.IMAGE_TAG_LATEST}" }
    failure { echo "❌ Falló el pipeline. Revisa el log." }
  }
}
