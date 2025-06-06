pipeline {
    agent any
    
    environment {
        PATH = "/opt/java/openjdk/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
        DOCKER_PATH = "/usr/local/bin/docker"
        
        DOCKER_IMAGE = "calculator-app"
        DOCKER_TAG = "${BUILD_NUMBER}"
        CONTAINER_NAME = "calculator-container"
        APP_PORT = "8081"
        INTERNAL_PORT = "8080"
        
        // Health check settings
        MAX_WAIT_TIME = "120" // Reduced to 2 minutes since Tomcat starts in ~1 minute
        CHECK_INTERVAL = "5"   // More frequent checks - every 5 seconds
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'project1', url: 'https://github.com/Hermosun/proj-mdp-152-155.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    sh """
                        docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .
                        docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
                    """
                    echo "✅ Docker image built successfully"
                }
            }
        }
        
        stage('Stop Previous Container') {
            steps {
                script {
                    echo "Checking for existing container: ${CONTAINER_NAME}"
                    sh '''
                        # Stop running container if exists
                        if docker ps -q -f name=${CONTAINER_NAME} | grep -q .; then
                            echo "Stopping existing container..."
                            docker stop ${CONTAINER_NAME}
                        fi
                        
                        # Remove container if exists
                        if docker ps -aq -f name=${CONTAINER_NAME} | grep -q .; then
                            echo "Removing existing container..."
                            docker rm ${CONTAINER_NAME}
                        fi
                        
                        echo "✅ Previous container cleanup completed"
                    '''
                }
            }
        }
        
        stage('Deploy Container') {
            steps {
                script {
                    echo "Deploying new container: ${CONTAINER_NAME}"
                    sh """
                        docker run -d \
                            --name ${CONTAINER_NAME} \
                            -p ${APP_PORT}:${INTERNAL_PORT} \
                            --restart=unless-stopped \
                            ${DOCKER_IMAGE}:latest
                    """
                    echo "✅ Container deployed successfully"
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo "Starting deployment verification..."
                    sh '''
                        echo "Container status:"
                        docker ps | grep ${CONTAINER_NAME}
                        
                        echo "Waiting for Tomcat to start (up to ${MAX_WAIT_TIME} seconds)..."
                        COUNTER=0
                        MAX_ATTEMPTS=$((MAX_WAIT_TIME / CHECK_INTERVAL))
                        
                        # First, wait for Tomcat to be ready (check logs for startup message)
                        echo "Monitoring Tomcat startup..."
                        while [ $COUNTER -lt $MAX_ATTEMPTS ]; do
                            ATTEMPT=$((COUNTER + 1))
                            echo "Startup check attempt $ATTEMPT/$MAX_ATTEMPTS..."
                            
                            # Check if Tomcat has started by looking for the startup message
                            if docker logs ${CONTAINER_NAME} 2>&1 | grep -q "Server startup in"; then
                                echo "✅ Tomcat has started successfully!"
                                break
                            fi
                            
                            echo "Tomcat still starting, waiting ${CHECK_INTERVAL} seconds..."
                            sleep ${CHECK_INTERVAL}
                            COUNTER=$((COUNTER + 1))
                        done
                        
                        if [ $COUNTER -eq $MAX_ATTEMPTS ]; then
                            echo "⚠️  Tomcat startup timeout, but continuing with health checks..."
                        fi
                        
                        # Now test multiple potential endpoints
                        echo "Testing application endpoints..."
                        COUNTER=0
                        
                        # Define possible endpoints to test
                        ENDPOINTS="/ /WebAppCal /WebAppCal/ /calculator /calculator/ /WebAppCal-1.0 /WebAppCal-1.0/"
                        
                        while [ $COUNTER -lt $MAX_ATTEMPTS ]; do
                            ATTEMPT=$((COUNTER + 1))
                            echo "Health check attempt $ATTEMPT/$MAX_ATTEMPTS..."
                            
                            # Test each endpoint
                            for endpoint in $ENDPOINTS; do
                                echo "Testing endpoint: http://localhost:${APP_PORT}${endpoint}"
                                
                                if curl -f -s --connect-timeout 3 --max-time 5 "http://localhost:${APP_PORT}${endpoint}" > /dev/null 2>&1; then
                                    echo "✅ SUCCESS: Application is responding at ${endpoint}!"
                                    
                                    # Show application response preview
                                    echo "Application response preview:"
                                    curl -s --connect-timeout 3 --max-time 5 "http://localhost:${APP_PORT}${endpoint}" | head -5
                                    
                                    # Show successful endpoint for future reference
                                    echo "📍 Working endpoint: http://localhost:${APP_PORT}${endpoint}"
                                    
                                    echo "✅ Deployment verification completed successfully!"
                                    exit 0
                                fi
                            done
                            
                            echo "No endpoints responding yet, waiting ${CHECK_INTERVAL} seconds..."
                            sleep ${CHECK_INTERVAL}
                            COUNTER=$((COUNTER + 1))
                        done
                        
                        # If we get here, detailed diagnostics
                        echo "❌ FAILED: Application did not respond within ${MAX_WAIT_TIME} seconds"
                        echo ""
                        echo "=== DIAGNOSTIC INFORMATION ==="
                        echo "Container status:"
                        docker ps | grep ${CONTAINER_NAME} || echo "Container not running!"
                        
                        echo ""
                        echo "Container logs (last 30 lines):"
                        docker logs --tail 30 ${CONTAINER_NAME}
                        
                        echo ""
                        echo "Testing raw connection to port ${APP_PORT}:"
                        nc -zv localhost ${APP_PORT} || echo "Port ${APP_PORT} is not accessible"
                        
                        echo ""
                        echo "Tomcat webapps directory contents:"
                        docker exec ${CONTAINER_NAME} ls -la /usr/local/tomcat/webapps/ || echo "Could not list webapps"
                        
                        echo ""
                        echo "Testing direct Tomcat manager (if available):"
                        curl -s --connect-timeout 3 "http://localhost:${APP_PORT}/manager/text/list" || echo "Manager not accessible"
                        
                        echo ""
                        echo "Container resource usage:"
                        docker stats --no-stream ${CONTAINER_NAME}
                        
                        exit 1
                    '''
                }
            }
        }
        
        stage('Post-Deploy Cleanup') {
            steps {
                script {
                    echo "Cleaning up old Docker images..."
                    sh '''
                        # Clean up old images (keep last 5 builds)
                        OLD_IMAGES=$(docker images ${DOCKER_IMAGE} --format "{{.Repository}}:{{.Tag}}" | \
                                   grep -v latest | tail -n +6)
                        
                        if [ -n "$OLD_IMAGES" ]; then
                            echo "Removing old images: $OLD_IMAGES"
                            echo "$OLD_IMAGES" | xargs -r docker rmi || echo "Some images could not be removed"
                        else
                            echo "No old images to clean up"
                        fi
                        
                        # Clean up dangling images
                        DANGLING_IMAGES=$(docker images -f "dangling=true" -q)
                        if [ -n "$DANGLING_IMAGES" ]; then
                            echo "Removing dangling images..."
                            echo "$DANGLING_IMAGES" | xargs -r docker rmi || echo "Some dangling images could not be removed"
                        fi
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "Pipeline execution completed at: ${new Date()}"
            }
        }
        success {
            echo """
            🎉 SUCCESS: Calculator app deployed successfully!
            📍 Application URL: http://localhost:${APP_PORT}
            🐳 Container: ${CONTAINER_NAME}
            🏷️  Image: ${DOCKER_IMAGE}:${DOCKER_TAG}
            
            Try accessing:
            - http://localhost:${APP_PORT}/
            - http://localhost:${APP_PORT}/WebAppCal/
            """
        }
        failure {
            script {
                echo """
                ❌ FAILURE: Pipeline failed!
                📋 Check the diagnostic information above
                🐳 Container logs: docker logs ${CONTAINER_NAME}
                🔍 Try manual testing: curl http://localhost:${APP_PORT}/
                """
                
                // Keep container running for debugging
                sh '''
                    echo "Container left running for debugging..."
                    echo "Access it with: docker exec -it ${CONTAINER_NAME} /bin/bash"
                    echo "Or check logs with: docker logs ${CONTAINER_NAME}"
                '''
            }
        }
    }
}
