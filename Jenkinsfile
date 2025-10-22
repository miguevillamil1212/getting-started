pipeline {
  agent any

  parameters {
    // Imagen y contenedor
    string(name: 'IMAGE_REPO',  defaultValue: 'miguel1212/parcial3-python', description: 'Repo en DockerHub (usuario/imagen)')
    string(name: 'APP_NAME',    defaultValue: 'parcial3-python',            description: 'Nombre del contenedor (deploy)')
    string(name: 'APP_PORT',    defaultValue: '5000',                       description: 'Puerto interno de Flask')
    string(name: 'HOST_PORT',   defaultValue: '5000',                       description: 'Puerto expuesto en el host Jenkins')

    // Modo remoto opcional (si NO puedes usar Docker local)
    booleanParam(name: 'USE_REMOTE', defaultValue: false, description: 'Usar Docker remoto vía SSH si el local no está disponible')
    string(name: 'REMOTE_DOCKER_HOST', defaultValue: '192.168.1.50', description: 'IP/Host del Docker remoto (si USE_REMOTE=true)')
    string(name: 'REMOTE_DOCKER_USER', defaultValue: 'docker', description: 'Usuario SSH en el host remoto')
    string(name: 'REMOTE_SSH_CRED_ID', defaultValue: 'remote-docker-ssh', description: 'ID de credencial SSH (SSH Username with private key)')
  }

  environment {
    // Credencial de Docker Hub (usuario/contraseña o token) — ya la tienes:
    DOCKERHUB_CREDENTIALS = 'docker-hub-credentials'
  }

  options {
    timestamps()
    timeout(time: 30, unit: 'MINUTES')
  }

  stages {
    stage('Checkout') {
      steps {
        echo '📦 Checkout del repositorio'
        checkout scm
      }
    }

    stage('Preflight: detectar Docker disponible') {
      steps {
        script {
          // Intenta Docker local
          def localOK = sh(returnStatus: true, script: 'docker version >/dev/null 2>&1') == 0
          env.DOCKER_MODE = localOK ? 'LOCAL' : 'UNKNOWN'

          if (!localOK) {
            echo '⚠️ Docker local NO disponible (posible "permission denied" o sin docker-cli).'
            if (params.USE_REMOTE) {
              echo "🌐 Intentando modo REMOTO via SSH en ${params.REMOTE_DOCKER_USER}@${params.REMOTE_DOCKER_HOST}"
              env.DOCKER_MODE = 'REMOTE'
            } else {
              echo '❌ No se puede usar Docker local y USE_REMOTE=false. Si ves "permission denied", es un tema de permisos del host.'
            }
          } else {
            echo '✅ Docker local disponible.'
          }
        }
      }
    }

    stage('Build & Push') {
      steps {
        script {
          def COMMIT = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
          def TAG_SHA = COMMIT
          def TAG_LATEST = "latest"

          if (env.DOCKER_MODE == 'LOCAL') {
            // ===== BUILT/PUSH LOCAL =====
            withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDENTIALS, usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
              sh """
                set -eux
                echo "\$DH_PASS" | docker login -u "\$DH_USER" --password-stdin
                # Build (dos tags)
                docker build --pull --no-cache -t ${params.IMAGE_REPO}:${TAG_SHA} -t ${params.IMAGE_REPO}:${TAG_LATEST} .
                # Push
                docker push ${params.IMAGE_REPO}:${TAG_SHA}
                docker push ${params.IMAGE_REPO}:${TAG_LATEST}
              """
            }
          } else if (env.DOCKER_MODE == 'REMOTE' && params.USE_REMOTE) {
            // ===== BUILT/PUSH REMOTO (sin sshagent) =====
            withCredentials([
              sshUserPrivateKey(credentialsId: params.REMOTE_SSH_CRED_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER'),
              usernamePassword(credentialsId: env.DOCKERHUB_CREDENTIALS, usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')
            ]) {
              sh """
                set -eux
                # DOCKER_HOST sobre SSH (no requiere socket local)
                export DOCKER_HOST=ssh://$SSH_USER@${params.REMOTE_DOCKER_HOST}

                # Verificar conexión al daemon remoto
                docker version

                # Login remoto a DockerHub
                echo "\$DH_PASS" | docker login -u "\$DH_USER" --password-stdin

                # Build remoto (dos tags)
                docker build --pull --no-cache -t ${params.IMAGE_REPO}:${TAG_SHA} -t ${params.IMAGE_REPO}:${TAG_LATEST} .

                # Push remoto
                docker push ${params.IMAGE_REPO}:${TAG_SHA}
                docker push ${params.IMAGE_REPO}:${TAG_LATEST}
              """
            }
          } else {
            error("""
            No hay Docker disponible:
            - Docker local no accesible (¿permission denied?)
            - USE_REMOTE=false o remoto no configurado
            Soluciones:
              1) Da permisos al Docker local del nodo Jenkins (tema del host, no del Jenkinsfile), o
              2) Activa USE_REMOTE=true y configura REMOTE_DOCKER_HOST/USER + REMOTE_SSH_CRED_ID.
            """.stripIndent())
          }
        }
      }
    }

    stage('Deploy') {
      when { branch 'main' }
      steps {
        script {
          if (env.DOCKER_MODE == 'LOCAL') {
            // ===== DEPLOY LOCAL =====
            sh """
              set -eux
              docker rm -f ${params.APP_NAME} || true
              docker pull ${params.IMAGE_REPO}:latest
              docker run -d --name ${params.APP_NAME} -p ${params.HOST_PORT}:${params.APP_PORT} ${params.IMAGE_REPO}:latest
            """
          } else if (env.DOCKER_MODE == 'REMOTE' && params.USE_REMOTE) {
            // ===== DEPLOY REMOTO =====
            withCredentials([sshUserPrivateKey(credentialsId: params.REMOTE_SSH_CRED_ID, keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
              sh """
                set -eux
                export DOCKER_HOST=ssh://$SSH_USER@${params.REMOTE_DOCKER_HOST}
                docker rm -f ${params.APP_NAME} || true
                docker pull ${params.IMAGE_REPO}:latest
                docker run -d --name ${params.APP_NAME} -p ${params.HOST_PORT}:${params.APP_PORT} ${params.IMAGE_REPO}:latest
              """
            }
          } else {
            error('No hay entorno (local/remoto) disponible para hacer deploy.')
          }
        }
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline OK. Imagen subida: ${params.IMAGE_REPO}:latest"
    }
    failure {
      echo "❌ Pipeline falló. Revisa logs arriba para la causa exacta."
    }
  }
}
