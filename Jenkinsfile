pipeline {
    agent any

    environment {
        DOCKER_HUB_REPO = 'miguel1212/parcial2-python'
        DOCKER_IMAGE = "${DOCKER_HUB_REPO}:${env.BUILD_NUMBER}"
        DOCKER_TAG_LATEST = "${DOCKER_HUB_REPO}:latest"
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
                    echo "DOCKER_HOST=${DOCKER_HOST}"
                    docker version
                '''
            }
        }

        stage('Construir imagen Docker') {
            steps {
                echo "⚙️ Construyendo la imagen Docker..."
                sh '''
                    docker build -t ${DOCKER_IMAGE} .
                    docker tag ${DOCKER_IMAGE} ${DOCKER_TAG_LATEST}
                '''
            }
        }

        stage('Prueba rápida (smoke test)') {
            steps {
                echo "🧪 Ejecutando prueba rápida..."
                sh '''
                    docker run --rm ${DOCKER_IMAGE} echo "✅ Imagen ejecutada correctamente"
                '''
            }
        }

        stage('Login y Push a Docker Hub') {
            steps {
                echo "🚀 Subiendo imagen a Docker Hub..."
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                        docker push ${DOCKER_IMAGE}
                        docker push ${DOCKER_TAG_LATEST}
                        docker logout
                    '''
                }
            }
        }

        stage('Desplegar (solo en main)') {
            when {
                branch 'main'
            }
            steps {
                echo "🌍 Desplegando la aplicación (solo en main)..."
                sh '''
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
    }
}
