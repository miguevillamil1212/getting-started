pipeline {
  agent any

  parameters {
    string(name: 'IMAGE_REPO',  defaultValue: 'miguel1212/parcial3-python', description: 'Repo en DockerHub')
    string(name: 'APP_PORT',    defaultValue: '5000', description: 'Puerto de la app Flask dentro del contenedor')
    string(name: 'HOST_PORT',   defaultValue: '5000', description: 'Puerto publicado en el host (Jenkins node)')
    string(name: 'APP_NAME',    defaultValue: 'parcial3-python', description: 'Nombre del contenedor en el host')
  }

  environment {
    DOCKERHUB_CREDENTIALS = 'docker-hub-credentials'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Push') {
      steps {
        script {
          def GIT_SHORT = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
          def IMAGE_TAG = GIT_SHORT
          def IMAGE_LATEST = "latest"

          withCredentials([usernamePassword(
              credentialsId: env.DOCKERHUB_CREDENTIALS,
              usernameVariable: 'DH_USER',
              passwordVariable: 'DH_PASS'
          )]) {
            sh """
              set -eux
              echo "\$DH_PASS" | docker login -u "\$DH_USER" --password-stdin

              docker build -t ${params.IMAGE_REPO}:${IMAGE_TAG} -t ${params.IMAGE_REPO}:${IMAGE_LATEST} .

              docker push ${params.IMAGE_REPO}:${IMAGE_TAG}
              docker push ${params.IMAGE_REPO}:${IMAGE_LATEST}
            """
          }
        }
      }
    }

    stage('Deploy (Local en nodo Jenkins)') {
      when { branch 'main' }  // despliega solo si la branch es main
      steps {
        script {
          sh """
            set -eux
            # detén/elimina previo si existe
            docker rm -f ${params.APP_NAME} || true

            # trae la última imagen recién pusheada
            docker pull ${params.IMAGE_REPO}:latest

            # ejecuta contenedor publicando HOST:HOST_PORT -> CONTENEDOR:APP_PORT
            docker run -d --name ${params.APP_NAME} -p ${params.HOST_PORT}:${params.APP_PORT} ${params.IMAGE_REPO}:latest
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
