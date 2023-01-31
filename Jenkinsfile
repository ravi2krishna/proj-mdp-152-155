pipeline{
    agent any
    options {
         buidDiscarder(logrotator(numToKeepStr: '5'))
    }
    environment { 
	DOCKERHUB_CREDENTIALS=credentials('docker-hub-kavitha')
    }
    stages {
	stage('Build docker image') {
            steps {
		sh 'docker build -t chidraboinakavitha/webcal:latest .'
	    }
	}
        stage('Remove existing container') {
	    steps {
		sh 'docker container rm -f app'
	    }
	}
	stage('Run container') {
            steps {
                sh 'docker container run -dt --name app -P chidraboinakavitha/webcal'
            }
        }
        stage('login') {
            steps {
		sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
	    }
	}
	stage('Push') {
            steps {
		sh 'docker push chidraboinakavitha/webcal:latest'
            }
	}
    }
    post {
	always {
	    sh 'docker logout'
	}
    }
}
