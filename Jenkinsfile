// Jenkins Declarative Pipeline for MERN Streaming App
// This pipeline builds Docker images and pushes them to AWS ECR
// Save this as Jenkinsfile in the repository root

pipeline {
    agent any
    
    options {
        // Keep only last 10 builds
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Timeout for the entire pipeline
        timeout(time: 1, unit: 'HOURS')
        // Add timestamps to console output
        timestamps()
    }
    
    // Environment variables
    environment {
        AWS_REGION = 'eu-west-2'
        AWS_ACCOUNT_ID = '975050024946'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_REPO = 'durga-streaming-app'
        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        GITHUB_REPO = 'https://github.com/durganaresh83/durga-StreamingApp.git'
    }
    
    parameters {
        choice(
            name: 'BUILD_SERVICES',
            choices: ['all', 'auth-service', 'streaming-service', 'admin-service', 'chat-service', 'frontend'],
            description: 'Which service(s) to build?'
        )
        booleanParam(
            name: 'PUSH_TO_ECR',
            defaultValue: true,
            description: 'Push images to ECR?'
        )
        booleanParam(
            name: 'USE_LATEST_TAG',
            defaultValue: true,
            description: 'Also tag as latest?'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "📦 Checking out code from GitHub..."
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/develop']],
                        userRemoteConfigs: [[
                            url: "${GITHUB_REPO}",
                            credentialsId: 'github-credentials'
                        ]]
                    ])
                }
            }
        }
        
        stage('Initialize') {
            steps {
                script {
                    echo "🔧 Initializing build environment..."
                    sh '''
                        echo "Build Number: ${BUILD_NUMBER}"
                        echo "Git Commit: ${GIT_COMMIT}"
                        echo "Image Tag: ${IMAGE_TAG}"
                        echo "ECR Registry: ${ECR_REGISTRY}"
                        
                        # Verify Docker is running
                        docker --version
                        echo "Docker daemon is running ✓"
                    '''
                }
            }
        }
        
        stage('ECR Login') {
            when {
                expression { params.PUSH_TO_ECR == true }
            }
            steps {
                script {
                    echo "🔐 Logging in to AWS ECR..."
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        
                        echo "Successfully logged in to ECR ✓"
                    '''
                }
            }
        }
        
        stage('Build Auth Service') {
            when {
                expression { params.BUILD_SERVICES == 'all' || params.BUILD_SERVICES == 'auth-service' }
            }
            steps {
                script {
                    echo "🏗️  Building auth-service..."
                    sh '''
                        docker build \
                            -f backend/authService/Dockerfile \
                            -t ${ECR_REGISTRY}/${ECR_REPO}/auth-service:${IMAGE_TAG} \
                            backend/authService
                        
                        if [ "${USE_LATEST_TAG}" = "true" ]; then
                            docker tag \
                                ${ECR_REGISTRY}/${ECR_REPO}/auth-service:${IMAGE_TAG} \
                                ${ECR_REGISTRY}/${ECR_REPO}/auth-service:latest
                        fi
                        
                        echo "auth-service built successfully ✓"
                    '''
                }
            }
        }
        
        stage('Build Streaming Service') {
            when {
                expression { params.BUILD_SERVICES == 'all' || params.BUILD_SERVICES == 'streaming-service' }
            }
            steps {
                script {
                    echo "🏗️  Building streaming-service..."
                    sh '''
                        docker build \
                            -f backend/streamingService/Dockerfile \
                            -t ${ECR_REGISTRY}/${ECR_REPO}/streaming-service:${IMAGE_TAG} \
                            backend/streamingService
                        
                        if [ "${USE_LATEST_TAG}" = "true" ]; then
                            docker tag \
                                ${ECR_REGISTRY}/${ECR_REPO}/streaming-service:${IMAGE_TAG} \
                                ${ECR_REGISTRY}/${ECR_REPO}/streaming-service:latest
                        fi
                        
                        echo "streaming-service built successfully ✓"
                    '''
                }
            }
        }
        
        stage('Build Admin Service') {
            when {
                expression { params.BUILD_SERVICES == 'all' || params.BUILD_SERVICES == 'admin-service' }
            }
            steps {
                script {
                    echo "🏗️  Building admin-service..."
                    sh '''
                        docker build \
                            -f backend/adminService/Dockerfile \
                            -t ${ECR_REGISTRY}/${ECR_REPO}/admin-service:${IMAGE_TAG} \
                            backend/adminService
                        
                        if [ "${USE_LATEST_TAG}" = "true" ]; then
                            docker tag \
                                ${ECR_REGISTRY}/${ECR_REPO}/admin-service:${IMAGE_TAG} \
                                ${ECR_REGISTRY}/${ECR_REPO}/admin-service:latest
                        fi
                        
                        echo "admin-service built successfully ✓"
                    '''
                }
            }
        }
        
        stage('Build Chat Service') {
            when {
                expression { params.BUILD_SERVICES == 'all' || params.BUILD_SERVICES == 'chat-service' }
            }
            steps {
                script {
                    echo "🏗️  Building chat-service..."
                    sh '''
                        docker build \
                            -f backend/chatService/Dockerfile \
                            -t ${ECR_REGISTRY}/${ECR_REPO}/chat-service:${IMAGE_TAG} \
                            backend/chatService
                        
                        if [ "${USE_LATEST_TAG}" = "true" ]; then
                            docker tag \
                                ${ECR_REGISTRY}/${ECR_REPO}/chat-service:${IMAGE_TAG} \
                                ${ECR_REGISTRY}/${ECR_REPO}/chat-service:latest
                        fi
                        
                        echo "chat-service built successfully ✓"
                    '''
                }
            }
        }
        
        stage('Build Frontend') {
            when {
                expression { params.BUILD_SERVICES == 'all' || params.BUILD_SERVICES == 'frontend' }
            }
            steps {
                script {
                    echo "🏗️  Building frontend..."
                    sh '''
                        docker build \
                            -f frontend/Dockerfile \
                            -t ${ECR_REGISTRY}/${ECR_REPO}/frontend:${IMAGE_TAG} \
                            --build-arg REACT_APP_AUTH_API_URL="${REACT_APP_AUTH_API_URL}" \
                            --build-arg REACT_APP_STREAMING_API_URL="${REACT_APP_STREAMING_API_URL}" \
                            --build-arg REACT_APP_STREAMING_PUBLIC_URL="${REACT_APP_STREAMING_PUBLIC_URL}" \
                            --build-arg REACT_APP_ADMIN_API_URL="${REACT_APP_ADMIN_API_URL}" \
                            --build-arg REACT_APP_CHAT_API_URL="${REACT_APP_CHAT_API_URL}" \
                            --build-arg REACT_APP_CHAT_SOCKET_URL="${REACT_APP_CHAT_SOCKET_URL}" \
                            frontend
                        
                        if [ "${USE_LATEST_TAG}" = "true" ]; then
                            docker tag \
                                ${ECR_REGISTRY}/${ECR_REPO}/frontend:${IMAGE_TAG} \
                                ${ECR_REGISTRY}/${ECR_REPO}/frontend:latest
                        fi
                        
                        echo "frontend built successfully ✓"
                    '''
                }
            }
        }
        
        stage('Push to ECR') {
            when {
                expression { params.PUSH_TO_ECR == true }
            }
            steps {
                script {
                    echo "📤 Pushing images to ECR..."
                    sh '''
                        services=()
                        
                        if [ "${BUILD_SERVICES}" = "all" ]; then
                            services=("auth-service" "streaming-service" "admin-service" "chat-service" "frontend")
                        else
                            services=("${BUILD_SERVICES}")
                        fi
                        
                        for service in "${services[@]}"; do
                            echo "Pushing ${service}..."
                            docker push ${ECR_REGISTRY}/${ECR_REPO}/${service}:${IMAGE_TAG}
                            
                            if [ "${USE_LATEST_TAG}" = "true" ]; then
                                docker push ${ECR_REGISTRY}/${ECR_REPO}/${service}:latest
                            fi
                        done
                        
                        echo "All images pushed successfully ✓"
                    '''
                }
            }
        }
        
        stage('Cleanup') {
            when {
                expression { params.PUSH_TO_ECR == true }
            }
            steps {
                script {
                    echo "🧹 Cleaning up old images..."
                    sh '''
                        # Remove dangling images
                        docker image prune -f --filter "dangling=true" || true
                        
                        # Keep only last 5 tagged images
                        docker image prune -a -f --filter "until=72h" || true
                        
                        echo "Cleanup completed ✓"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "🔍 Build stage: ${currentBuild.result}"
                // Archive logs
                archiveArtifacts artifacts: '**/logs/**', allowEmptyArchive: true
            }
        }
        success {
            script {
                echo "✅ Pipeline succeeded!"
                // Send success notification
                def buildImage = "${ECR_REGISTRY}/${ECR_REPO}/${params.BUILD_SERVICES}:${IMAGE_TAG}"
                echo "📦 Image built and pushed: ${buildImage}"
            }
        }
        failure {
            script {
                echo "❌ Pipeline failed!"
                // Send failure notification
            }
        }
        unstable {
            script {
                echo "⚠️  Pipeline is unstable"
            }
        }
        aborted {
            script {
                echo "⏹️  Pipeline was aborted"
            }
        }
    }
}
