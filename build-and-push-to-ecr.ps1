# Build and Push Docker Images to AWS ECR
# This script builds all MERN application components and pushes them to ECR

# Configuration
$AWS_REGION = "eu-west-2"  # Change to your AWS region
$ECR_REPO_NAME = "durga-streaming-app"
$AWS_ACCOUNT_ID = "975050024946"  # You need to fill this or it will be retrieved

# Color output functions
function Write-Success {
    Write-Host $args -ForegroundColor Green
}

function Write-Error-Custom {
    Write-Host $args -ForegroundColor Red
}

function Write-Info {
    Write-Host $args -ForegroundColor Cyan
}

# Get AWS Account ID if not set
if (-not $AWS_ACCOUNT_ID) {
    Write-Info "Retrieving AWS Account ID..."
    try {
        $AWS_ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
        Write-Success "AWS Account ID: $AWS_ACCOUNT_ID"
    }
    catch {
        Write-Error-Custom "Failed to retrieve AWS Account ID. Please ensure AWS CLI is configured."
        exit 1
    }
}

$ECR_REGISTRY = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
Write-Info "ECR Registry: $ECR_REGISTRY"

# Function to build and push image
function Build-And-Push-Image {
    param(
        [string]$ServiceName,
        [string]$DockerfilePath,
        [string]$BuildContext,
        [hashtable]$BuildArgs = @{}
    )

    $IMAGE_NAME = "$ECR_REGISTRY/$ECR_REPO_NAME/$ServiceName"
    $IMAGE_TAG = "latest"
    $FULL_IMAGE_NAME = "$IMAGE_NAME`:$IMAGE_TAG"

    Write-Info "`n========================================`n"
    Write-Info "Building and pushing: $ServiceName"
    Write-Info "Image: $FULL_IMAGE_NAME`n"

    # Build the image
    Write-Info "Step 1: Building Docker image..."
    $buildCommand = "docker build -f `"$DockerfilePath`" -t `"$FULL_IMAGE_NAME`""
    
    # Add build arguments if provided
    foreach ($key in $BuildArgs.Keys) {
        $buildCommand += " --build-arg $key=`"$($BuildArgs[$key])`""
    }
    
    $buildCommand += " `"$BuildContext`""
    
    Invoke-Expression $buildCommand
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to build $ServiceName"
        return $false
    }
    
    Write-Success "✓ Image built successfully"

    # Push the image
    Write-Info "Step 2: Pushing image to ECR..."
    docker push $FULL_IMAGE_NAME
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to push $ServiceName to ECR"
        return $false
    }
    
    Write-Success "✓ Image pushed successfully to ECR`n"
    return $true
}

# Main execution
Write-Info "========================================`n"
Write-Info "Docker Build and Push to ECR Script"
Write-Info "========================================`n"

# Change to project root
$projectRoot = Get-Location
Write-Info "Project root: $projectRoot`n"

# Array to track build status
$buildResults = @()

# 1. Build and push Auth Service
$buildResults += @{
    Service = "auth-service"
    Success = (Build-And-Push-Image -ServiceName "auth-service" -DockerfilePath "backend/authService/Dockerfile" -BuildContext "backend/authService" )
}

# 2. Build and push Streaming Service
$buildResults += @{
    Service = "streaming-service"
    Success = (Build-And-Push-Image -ServiceName "streaming-service" -DockerfilePath "backend/streamingService/Dockerfile" -BuildContext "backend/streamingService")
}

# 3. Build and push Admin Service
$buildResults += @{
    Service = "admin-service"
    Success = (Build-And-Push-Image -ServiceName "admin-service" -DockerfilePath "backend/adminService/Dockerfile" -BuildContext "backend/adminService")
}

# 4. Build and push Chat Service
$buildResults += @{
    Service = "chat-service"
    Success = (Build-And-Push-Image -ServiceName "chat-service" -DockerfilePath "backend/chatService/Dockerfile" -BuildContext "backend/chatService")
}

# 5. Build and push Frontend
$frontendBuildArgs = @{
    REACT_APP_AUTH_API_URL = $env:REACT_APP_AUTH_API_URL -or "https://api.example.com/auth"
    REACT_APP_STREAMING_API_URL = $env:REACT_APP_STREAMING_API_URL -or "https://api.example.com/streaming"
    REACT_APP_STREAMING_PUBLIC_URL = $env:REACT_APP_STREAMING_PUBLIC_URL -or "https://api.example.com"
    REACT_APP_ADMIN_API_URL = $env:REACT_APP_ADMIN_API_URL -or "https://api.example.com/admin"
    REACT_APP_CHAT_API_URL = $env:REACT_APP_CHAT_API_URL -or "https://api.example.com/chat"
    REACT_APP_CHAT_SOCKET_URL = $env:REACT_APP_CHAT_SOCKET_URL -or "https://api.example.com"
}

$buildResults += @{
    Service = "frontend"
    Success = (Build-And-Push-Image -ServiceName "frontend" -DockerfilePath "frontend/Dockerfile" -BuildContext "." -BuildArgs $frontendBuildArgs)
}

# Summary
Write-Info "`n========================================`n"
Write-Info "Build Summary"
Write-Info "========================================`n"

$successCount = 0
foreach ($result in $buildResults) {
    if ($result.Success) {
        Write-Success "✓ $($result.Service)"
        $successCount++
    }
    else {
        Write-Error-Custom "✗ $($result.Service)"
    }
}

Write-Info "`nTotal: $successCount/$($buildResults.Count) services built and pushed successfully"

if ($successCount -eq $buildResults.Count) {
    Write-Success "`n✓ All services built and pushed successfully!`n"
    Write-Info "Next steps:"
    Write-Info "1. Update your deployment configuration with the new image URIs"
    Write-Info "2. ECR Registry: $ECR_REGISTRY"
    Write-Info "3. Repository: $ECR_REPO_NAME`n"
    exit 0
}
else {
    Write-Error-Custom "`n✗ Some services failed. Please review the errors above.`n"
    exit 1
}
