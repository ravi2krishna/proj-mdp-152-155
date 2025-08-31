pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('Docker-hub')
        IMAGE_NAME = "tracyedisemi/webapp-calculator"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'project-3', url: 'https://github.com/Tracyerite/proj-mdp-152-155.git'
            }
        }
        stage('Build Docker Image') {
            steps {
                // Build from the root of the repo, where pom.xml exists
                sh 'docker build -f project-3/Dockerfile -t $IMAGE_NAME:latest .'
            }
        }
        stage('Push to DockerHub') {
            steps {
                sh "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"
                sh 'docker push $IMAGE_NAME:latest'
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh 'kubectl apply -f project-3/k8s/deployment.yaml'
                    sh 'kubectl apply -f project-3/k8s/service.yaml'
                }
            }
        }
    }
}
