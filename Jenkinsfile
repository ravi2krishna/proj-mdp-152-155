pipeline {
  agent any

  environment {
    IMAGE_NAME = 'ruthp123/calculator-app'  // Change to your Docker Hub repo
  }

  stages {
    stage('Clone Repository') {
      steps {
        git branch: 'Project-1', url: 'https://github.com/rutheki24/proj-mdp-152-155.git'
      }
    }

    stage('Build Maven App') {
      steps {
        sh '''
          export PATH=/opt/apache-maven/bin:$PATH
          mvn clean package -DskipTests
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $IMAGE_NAME .'
      }
    }

    stage('Push Docker Image to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'Dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh """
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker push $IMAGE_NAME
          """
        }
      }
    }

    stage('Run Docker Container') {
      steps {
        sh '''
          docker stop calculator-container || true
          docker rm calculator-container || true
          docker run -d --name calculator-container -p 8081:8080 $IMAGE_NAME
        '''
      }
    }
  }

  post {
    success {
      echo '✅ Application container is running on http://<EC2-IP>:8081'
    }
    failure {
      echo '❌ Build or container run failed.'
    }
  }
}
