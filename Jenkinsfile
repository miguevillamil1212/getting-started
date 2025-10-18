pipeline {
  agent any

  parameters {
    string(name: 'REMOTE_DOCKER_HOST', defaultValue: '192.168.1.50', description: 'Host/IP del Docker remoto')
    string(name: 'REMOTE_DOCKER_USER', defaultValue: 'docker', description: 'Usuario SSH con permisos de Docker')
    string(name: 'IMAGE_REPO', defaultValue: 'miguel1212/parcial3-python', description: 'Repo en DockerHub para pushear la imagen')
    string(name: 'DEPLOY_NAME', defaultValue: 'parcial3-python', description: 'Nombre del contenedor a ejecutar en el host remoto')
    string(name: 'DEPLOY_PORT', defaultValue: '5000', description: 'Puerto a publicar en el host remoto')
  }

  environment {
    // Docker Hub registry
    REGISTRY = 'https://index.docker.io/v1/'
    // Jenkins credentials IDs
    DOCKERHUB_CREDENTIALS = 'dockerhub-credentials'    // (Usuario/Token de DockerHub)
    REMOTE_SSH_CREDENTIALS = 'remote-docker-ssh'       // (SSH private key al host remoto)
    // DOCKER_HOST sobre SSH hacia el host remoto (sin tocar el Docker local)
    DOCKER_HOST = "ssh://${params.REMOTE_DOCKER_USER}@${params.REMOTE_DOCKER_HOST}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Push (Remote Docker over SSH)') {
      steps {
        // Habilita el agente SSH para que docker CLI use DOCKER_HOST=ssh://...
        sshagent (credentials: ["${env.REMOTE_SSH_CREDENTIALS}"]) {
          script {
            def GIT_SHORT = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
            def IMAGE_TAG = GIT_SHORT
            def IMAGE_LATEST = "latest"

            // Login a DockerHub en el host remoto (vía DOCKER_HOST=ssh://)
            withCredentials([usernamePassword(credentialsId: "${env.DOCKERHUB_CREDENTIALS}", usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
              sh """
                # Asegurar que el cliente docker existe
                docker version

                # Login contra DockerHub (se guarda en ~/.docker/config.json del usuario remoto)
                echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin

                # Construir imagen en el daemon remoto
                docker build -t ${params.IMAGE_REPO}:${IMAGE_TAG} -t ${params.IMAGE_REPO}:${IMAGE_LATEST} .

                # Push de ambas etiquetas
                docker push ${params.IMAGE_REPO}:${IMAGE_TAG}
                docker push ${params.IMAGE_REPO}:${IMAGE_LATEST}
              """
            }
          }
        }
      }
    }

    stage('Deploy (Remote)') {
      when { branch 'main' }  // despliega solo en main
      steps {
        sshagent (credentials: ["${env.REMOTE_SSH_CREDENTIALS}"]) {
          sh """
            # Detener/Eliminar contenedor previo si existe
            docker rm -f ${params.DEPLOY_NAME} || true

            # Traer última imagen
            docker pull ${params.IMAGE_REPO}:latest

            # Ejecutar nuevo contenedor publicado en el host remoto
            docker run -d --name ${params.DEPLOY_NAME} -p ${params.DEPLOY_PORT}:5000 ${params.IMAGE_REPO}:latest
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
