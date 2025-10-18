pipeline {
  agent any
  environment {
    REGISTRY = "docker.io"
    IMAGE_REPO = "miguel1212/parcial2-python"
    DOCKERHUB_CREDENTIALS = "docker-hub-credentials"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build Docker Image') {
      steps {
        script {
          GIT_SHORT = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
          IMAGE_TAG = "${GIT_SHORT}"
          IMAGE_LATEST = "latest"
          sh """
            docker build -t ${IMAGE_REPO}:${IMAGE_TAG} -t ${IMAGE_REPO}:${IMAGE_LATEST} .
          """
        }
      }
    }

    stage('Push to DockerHub') {
      steps {
        script {
          docker.withRegistry("https://${REGISTRY}", "${DOCKERHUB_CREDENTIALS}") {
            sh "docker push ${IMAGE_REPO}:${IMAGE_TAG}"
            sh "docker push ${IMAGE_REPO}:latest"
          }
        }
      }
    }

    stage('Deploy Container') {
      when { branch 'main' }
      steps {
        script {
          sh """
            docker rm -f parcial3-python || true
            docker pull ${IMAGE_REPO}:latest
            docker run -d --name parcial3-python -p 5000:5000 ${IMAGE_REPO}:latest
          """
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline finalizado."
    }
  }
}
