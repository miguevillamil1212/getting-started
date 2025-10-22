pipeline {
  agent any

  environment {
    // Hablar con el Docker-in-Docker (DinD) que levantaste en 'dind:2375'
    DOCKER_HOST          = 'tcp://dind:2375'

    DOCKER_HUB_REPO      = 'miguel1212/parcial2-python'
    DOCKER_IMAGE         = "${env.DOCKER_HUB_REPO}:${env.BUILD_NUMBER}"
    DOCKER_TAG_LATEST    = "${env.DOCKER_HUB_REPO}:latest"
    DOCKER_BUILDKIT      = '1'
    COMPOSE_PROJECT_NAME = 'parcial2-python'
  }

  options {
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

    stage('Verificar Docker (DinD)') {
      steps {
        echo "🔎 Verificando conexión con Docker (DinD)"
        sh '''
          set -e
          echo "DOCKER_HOST=${DOCKER_HOST}"
          docker version
          docker info | sed -n '1,30p'
        '''
      }
    }

    stage('Construir imagen Docker') {
      steps {
        echo "⚙️ Construyendo la imagen Docker…"
        sh '''
          set -e
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
          expression { fileExists('docker-compose.yml') || fileExists('compose.yml') || fileExists('compose.yaml') }
        }
      }
      steps {
        echo "🌍 Desplegando la aplicación (solo en main)…"
        sh '''
          set -e
          docker compose version
          docker compose down || true
          docker compose up -d
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
      script {
        try {
          sh 'docker image prune -f || true'
          sh 'docker container prune -f || true'
        } catch (e) {
          echo "Limpieza omitida: Docker no disponible."
        }
      }
    }
  }
}
