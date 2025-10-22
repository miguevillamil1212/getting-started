pipeline {
  agent {
    docker {
      // Imagen con Docker CLI (incluye compose plugin en versiones recientes)
      image 'docker:27.1-cli'
      // Monta el socket del host y la carpeta de config para evitar re-login reiterado;
      // ejecuta como root para no depender del grupo 'docker'
      args '--privileged -u 0:0 -v /var/run/docker.sock:/var/run/docker.sock -v $HOME/.docker:/root/.docker'
      reuseNode true
    }
  }

  environment {
    DOCKER_HUB_REPO   = 'miguel1212/parcial2-python'
    DOCKER_IMAGE      = "${env.DOCKER_HUB_REPO}:${env.BUILD_NUMBER}"
    DOCKER_TAG_LATEST = "${env.DOCKER_HUB_REPO}:latest"
    // Opcional: fuerza modo BuildKit para mejoras
    DOCKER_BUILDKIT   = '1'
    COMPOSE_PROJECT_NAME = 'parcial2-python'
  }

  options {
    // Evita logs gigantes cuando hay pull/build
    ansiColor('xterm')
    timestamps()
    skipDefaultCheckout(true)
  }

  stages {

    stage('Checkout') {
      steps {
        echo "📦 Checkout del repositorio"
        checkout scm
      }
    }

    stage('Verificar entorno Docker') {
      steps {
        echo "🔎 Verificando conexión con Docker"
        sh '''
          set -e
          echo "DOCKER_HOST=${DOCKER_HOST:-unix:///var/run/docker.sock}"
          # Comprobación del socket
          if [ ! -S /var/run/docker.sock ]; then
            echo "❌ No se encuentra /var/run/docker.sock montado en el agente."
            echo "   Si Jenkins corre en contenedor, levántalo con: -v /var/run/docker.sock:/var/run/docker.sock"
            exit 2
          fi
          ls -l /var/run/docker.sock || true
          # Prueba de versión
          docker version
          # Prueba de permisos efectiva: lista imágenes (no debería fallar)
          docker images >/dev/null
        '''
      }
    }

    stage('Construir imagen Docker') {
      steps {
        echo "⚙️ Construyendo la imagen Docker…"
        sh '''
          set -e
          echo "→ docker build -t ${DOCKER_IMAGE} ."
          docker build -t ${DOCKER_IMAGE} .
          docker tag ${DOCKER_IMAGE} ${DOCKER_TAG_LATEST}
          docker images | head -n 10
        '''
      }
    }

    stage('Prueba rápida (smoke test)') {
      steps {
        echo "🧪 Ejecutando prueba rápida…"
        sh '''
          set -e
          # Si tu imagen es una app web/servicio, adapta el comando de prueba
          docker run --rm ${DOCKER_IMAGE} sh -c 'echo "✅ Imagen ejecutada correctamente"'
        '''
      }
    }

    stage('Login y Push a Docker Hub') {
      steps {
        echo "🚀 Subiendo imagen a Docker Hub…"
        withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            set -e
            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
            docker push ${DOCKER_IMAGE}
            docker push ${DOCKER_TAG_LATEST}
            docker logout || true
          '''
        }
      }
    }

    stage('Desplegar (solo en main)') {
      when {
        allOf {
          branch 'main'
          expression {
            // Solo intentar si existe archivo compose
            return fileExists('docker-compose.yml') || fileExists('compose.yml') || fileExists('compose.yaml')
          }
        }
      }
      steps {
        echo "🌍 Desplegando la aplicación (solo en main)…"
        sh '''
          set -e
          # docker compose plugin viene integrado en docker CLI moderno; si no, instala compose plugin o usa "docker-compose" si lo tienes.
          if docker compose version >/dev/null 2>&1; then
            docker compose down || true
            docker compose up -d
          else
            echo "⚠️ 'docker compose' no está disponible en esta imagen."
            echo "   Opciones: usar imagen 'docker:27.1-cli' con plugin compose, o instalar el plugin en el agente."
            exit 3
          fi
        '''
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline completado exitosamente. Imagen: ${DOCKER_IMAGE}"
    }
    failure {
      echo "❌ El pipeline falló. Revisa los logs de Jenkins."
      archiveArtifacts artifacts: '**/logs/*.log', allowEmptyArchive: true
    }
    cleanup {
      // Libera espacio (opcional)
      sh '''
        docker image prune -f || true
        docker container prune -f || true
      '''
    }
  }
}
