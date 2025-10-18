pipeline {
  agent any

  parameters {
    string(name: 'IMAGE_REPO',  defaultValue: 'miguel1212/parcial3-python', description: 'Repo en DockerHub')
    string(name: 'APP_NAME',    defaultValue: 'parcial3-python',            description: 'Nombre del contenedor en el host Jenkins')
    string(name: 'APP_PORT',    defaultValue: '5000',                       description: 'Puerto de la app dentro del contenedor (Flask)')
    string(name: 'HOST_PORT',   defaultValue: '5000',                       description: 'Puerto publicado en el host (Jenkins node)')
  }

  environment {
    DOCKERHUB_CREDENTIALS = 'docker-hub-credentials'
  }

  stages {
    stage('Checkout') {
      steps {
        echo '📦 Checkout del repositorio'
        checkout scm
      }
    }

    stage('Build & Push') {
      steps {
        script {
          // Etiquetas: latest y short SHA
          def COMMIT = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
          def TAG_SHA = COMMIT
          def TAG_LATEST = "latest"

          withCredentials([usernamePassword(
              credentialsId: env.DOCKERHUB_CREDENTIALS,
              usernameVariable: 'DH_USER',
              passwordVariable: 'DH_PASS'
          )]) {
            sh """
              set -eux
              echo "\$DH_PASS" | docker login -u "\$DH_USER" --password-stdin

              # Construir imagen con 2 tags
              docker build -t ${params.IMAGE_REPO}:${TAG_SHA} -t ${params.IMAGE_REPO}:${TAG_LATEST} .

              # Push de ambas etiquetas
              docker push ${params.IMAGE_REPO}:${TAG_SHA}
              docker push ${params.IMAGE_REPO}:${TAG_LATEST}
            """
          }
        }
      }
    }

    stage('Deploy (Local en nodo Jenkins)') {
      when { branch 'main' } // despliega solo si la branch es main
      steps {
        script {
          sh """
            set -eux
            # Detener/eliminar contenedor previo si existe
            docker rm -f ${params.APP_NAME} || true

            # Traer última imagen
            docker pull ${params.IMAGE_REPO}:latest

            # Ejecutar contenedor publicando HOST:${params.HOST_PORT} -> CT:${params.APP_PORT}
            docker run -d --name ${params.APP_NAME} -p ${params.HOST_PORT}:${params.APP_PORT} ${params.IMAGE_REPO}:latest
          """
        }
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline OK. Imagen: ${params.IMAGE_REPO}:latest"
    }
    failure {
      echo "❌ Pipeline falló. Revisa logs."
    }
  }
}
