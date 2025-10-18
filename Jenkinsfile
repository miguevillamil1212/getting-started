pipeline {
  agent any

  parameters {
    string(name: 'REMOTE_DOCKER_HOST', defaultValue: '192.168.1.50', description: 'Host/IP del Docker remoto')
    string(name: 'IMAGE_REPO',         defaultValue: 'miguel1212/parcial3-python', description: 'Repo en DockerHub para pushear la imagen')
    string(name: 'DEPLOY_NAME',        defaultValue: 'parcial3-python', description: 'Nombre del contenedor remoto')
    string(name: 'DEPLOY_PORT',        defaultValue: '5000', description: 'Puerto publicado en el host remoto')
  }

  environment {
    DOCKERHUB_CREDENTIALS = 'dockerhub-credentials'
    REMOTE_SSH_CREDENTIALS = 'remote-docker-ssh'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Push (Remote Docker over SSH)') {
      steps {
        script {
          def GIT_SHORT = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
          def IMAGE_TAG = GIT_SHORT
          def IMAGE_LATEST = "latest"

          withCredentials([
            sshUserPrivateKey(credentialsId: env.REMOTE_SSH_CREDENTIALS,
                              keyFileVariable: 'SSH_KEY',
                              usernameVariable: 'SSH_USER'),
            usernamePassword(credentialsId: env.DOCKERHUB_CREDENTIALS,
                             usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')
          ]) {
            sh """
              # Usar Docker remoto vía SSH sin necesitar el socket local
              export DOCKER_HOST=ssh://$SSH_USER@${params.REMOTE_DOCKER_HOST}

              # Verifica conexión al daemon remoto
              docker version

              # Login a DockerHub (se guarda en ~/.docker del usuario remoto)
              echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin

              # Construcción y push
              docker build -t ${params.IMAGE_REPO}:${IMAGE_TAG} -t ${params.IMAGE_REPO}:${IMAGE_LATEST} .
              docker push ${params.IMAGE_REPO}:${IMAGE_TAG}
              docker push ${params.IMAGE_REPO}:${IMAGE_LATEST}
            """
          }
        }
      }
    }

    stage('Deploy (Remote)') {
      when { branch 'main' } // despliega solo en main
      steps {
        withCredentials([
          sshUserPrivateKey(credentialsId: env.REMOTE_SSH_CREDENTIALS,
                            keyFileVariable: 'SSH_KEY',
                            usernameVariable: 'SSH_USER')
        ]) {
          sh """
            export DOCKER_HOST=ssh://$SSH_USER@${params.REMOTE_DOCKER_HOST}

            # Detener/limpiar si ya existe
            docker rm -f ${params.DEPLOY_NAME} || true

            # Traer última imagen y ejecutar
            docker pull ${params.IMAGE_REPO}:latest
            docker run -d --name ${params.DEPLOY_NAME} -p ${params.DEPLOY_PORT}:5000 ${params.IMAGE_REPO}:latest
          """
        }
      }
    }
  }

  post {
    always { echo "Pipeline finalizado." }
  }
}
