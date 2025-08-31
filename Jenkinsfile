pipeline {
    agent any

    environment {
        IMAGE_NAME = 'nottiey/javacal-webapp'
        TAG = 'latest'
        REMOTE_USER = 'ec2-user'
        REMOTE_HOST = '54.86.21.245'
        REMOTE_DOCKER_PORT = '8083'
        SSH_CRED_ID = 'tomcat-ssh-key'
    }

    stages {
        stage('Clone Code') {
            steps {
                git branch: 'project-1', url: 'https://github.com/nottie-noe/proj-mdp-152-155.git'
            }
        }

        stage('Build with Maven (in Docker)') {
            steps {
                sh 'docker run --rm -v "$PWD":/app -w /app maven:3.8.1-openjdk-8 mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE_NAME:$TAG .'
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push $IMAGE_NAME:$TAG
                    '''
                }
            }
        }

        stage('Deploy to Tomcat Server') {
            steps {
                sshagent(credentials: [env.SSH_CRED_ID]) {
                    sh """
ssh -o StrictHostKeyChecking=no $REMOTE_USER@$REMOTE_HOST << EOF
docker pull $IMAGE_NAME:$TAG
docker stop webapp || true
docker rm webapp || true
docker run -d -p $REMOTE_DOCKER_PORT:8080 --name webapp $IMAGE_NAME:$TAG
EOF
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful! App should be live at http://$REMOTE_HOST:$REMOTE_DOCKER_PORT"

            // Email success
            mail to: 'thandonoe.ndlovu@gmail.com',
                 subject: "SUCCESS: Jenkins Build #${env.BUILD_NUMBER}",
                 body: "The Jenkins build was successful.\nApplication deployed at: http://$REMOTE_HOST:$REMOTE_DOCKER_PORT"
        }

        failure {
            echo "❌ Pipeline failed!"

            // Email failure
            mail to: 'thandonoe.ndlovu@gmail.com',
                 subject: "FAILURE: Jenkins Build #${env.BUILD_NUMBER}",
                 body: "The Jenkins build has failed. Please investigate the job: ${env.BUILD_URL}"
        }
    }
}
