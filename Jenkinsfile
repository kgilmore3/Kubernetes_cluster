pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                sh 'docker build -t <your-image-name>:<tag> .'
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', passwordVariable: 'DOCKER_HUB_PASSWORD', usernameVariable: 'DOCKER_HUB_USERNAME')]) {
                    sh 'echo $DOCKER_HUB_PASSWORD | docker login --username $DOCKER_HUB_USERNAME --password-stdin'
                    sh 'docker push <your-image-name>:<tag>'
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([string(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh 'echo $KUBECONFIG > kubeconfig.yaml'
                    sh 'kubectl config use-context <your-context-name>'
                    sh 'kubectl apply -f deployment.yaml'
                }
            }
        }

        stage('Run Tests') {
            steps {
                sh 'run-your-tests-here'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
