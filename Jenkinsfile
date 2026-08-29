pipeline {

    agent any

    environment {
        DOCKER_IMAGE = "aoucheti/todo-app"
        DOCKER_CREDENTIALS = "dockerhub-credentials"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install dependencies') {
            steps {
                dir('app') {
					sh 'npm ci'
				}
            }
        }

        stage('Unit tests') {
            steps {
                dir('app') {
					sh 'npm test'
				}
            }
        }

        stage('Build Docker image') {
            steps {
                sh """
                    docker build \
                        -t ${DOCKER_IMAGE}:${BUILD_NUMBER} \
                        -t ${DOCKER_IMAGE}:latest .
                """
            }
        }

        stage('Push Docker image') {
            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIALS}",
                        usernameVariable: 'aoucheti',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {

                    sh '''
                        echo "$DOCKER_PASSWORD" | \
                            docker login \
                            -u "$DOCKER_USERNAME" \
                            --password-stdin

                        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        docker push ${DOCKER_IMAGE}:latest

                        docker logout
                    '''
                }
            }
        }

        stage('Deploy Kubernetes') {
            steps {
                sh '''
                    kubectl apply -f k8s/

                    kubectl set image deployment/todo-app \
                        todo-app=${DOCKER_IMAGE}:${BUILD_NUMBER}

                    kubectl rollout status deployment/todo-app
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline terminé avec succès.'
        }

        failure {
            echo 'Le pipeline a échoué.'
        }
    }
}