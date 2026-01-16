# Docker Build and Push to AWS ECR Guide

## Overview
This guide explains how to containerize the MERN Streaming App and push Docker images to Amazon ECR.

## Prerequisites

1. **Docker Desktop** installed and running
2. **AWS CLI** installed and configured with your credentials
3. **AWS Account** with ECR repository created: `durga-streaming-app`
4. **ECR login** completed: `aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com`

## Application Components

The application consists of 5 containerized services:

| Service | Port | Dockerfile | Purpose |
|---------|------|-----------|---------|
| **Frontend** | 80 (3000 locally) | `frontend/Dockerfile` | React web application |
| **Auth Service** | 3001 | `backend/authService/Dockerfile` | User authentication & JWT |
| **Streaming Service** | 3002 | `backend/streamingService/Dockerfile` | Video streaming & management |
| **Admin Service** | 3003 | `backend/adminService/Dockerfile` | Admin panel backend |
| **Chat Service** | 3004 | `backend/chatService/Dockerfile` | Real-time chat with Socket.io |

## Dockerfile Overview

### Frontend Dockerfile
- **Base**: Node 18 Alpine (build stage) → Nginx Alpine (production)
- **Build Args**: React app API URLs for all backend services
- **Port**: 80
- **Strategy**: Multi-stage build for optimized production image

### Backend Service Dockerfiles
- **Base**: Node 18 Alpine
- **Install**: Production dependencies only
- **Port**: Service-specific (3001-3004)
- **Node Env**: Production

## Step-by-Step Instructions

### Step 1: Verify Environment Variables

Update your `.env` file with production values:

```bash
# AWS
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=ap-south-1
AWS_S3_BUCKET=your-s3-bucket-name
AWS_CDN_URL=https://your-cloudfront.cloudfront.net

# Frontend URLs (for production, use your domain)
REACT_APP_AUTH_API_URL=https://api.yourdomain.com/auth
REACT_APP_STREAMING_API_URL=https://api.yourdomain.com/streaming
REACT_APP_ADMIN_API_URL=https://api.yourdomain.com/admin
REACT_APP_CHAT_API_URL=https://api.yourdomain.com/chat
REACT_APP_CHAT_SOCKET_URL=https://api.yourdomain.com
```

### Step 2: ECR Login

```powershell
# Get login token and authenticate Docker
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-south-1.amazonaws.com
```

Expected output: `Login Succeeded`

### Step 3: Build and Push Images

#### Option A: Using the Build Script (Recommended)

```powershell
# From the project root directory
./build-and-push-to-ecr.ps1
```

This script will:
1. Retrieve your AWS Account ID
2. Build all 5 Docker images
3. Tag them for ECR
4. Push to your ECR repository
5. Display a summary

#### Option B: Manual Build and Push

**Build Frontend:**
```powershell
$ECR_REGISTRY = "$(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-south-1.amazonaws.com"
$ECR_REPO = "durga-streaming-app"

docker build -f frontend/Dockerfile `
  -t $ECR_REGISTRY/$ECR_REPO/frontend:latest `
  --build-arg REACT_APP_AUTH_API_URL="https://api.yourdomain.com/auth" `
  --build-arg REACT_APP_STREAMING_API_URL="https://api.yourdomain.com/streaming" `
  --build-arg REACT_APP_STREAMING_PUBLIC_URL="https://api.yourdomain.com" `
  --build-arg REACT_APP_ADMIN_API_URL="https://api.yourdomain.com/admin" `
  --build-arg REACT_APP_CHAT_API_URL="https://api.yourdomain.com/chat" `
  --build-arg REACT_APP_CHAT_SOCKET_URL="https://api.yourdomain.com" .

docker push $ECR_REGISTRY/$ECR_REPO/frontend:latest
```

**Build Auth Service:**
```powershell
docker build -f backend/authService/Dockerfile `
  -t $ECR_REGISTRY/$ECR_REPO/auth-service:latest .

docker push $ECR_REGISTRY/$ECR_REPO/auth-service:latest
```

**Build Streaming Service:**
```powershell
docker build -f backend/streamingService/Dockerfile `
  -t $ECR_REGISTRY/$ECR_REPO/streaming-service:latest .

docker push $ECR_REGISTRY/$ECR_REPO/streaming-service:latest
```

**Build Admin Service:**
```powershell
docker build -f backend/adminService/Dockerfile `
  -t $ECR_REGISTRY/$ECR_REPO/admin-service:latest .

docker push $ECR_REGISTRY/$ECR_REPO/admin-service:latest
```

**Build Chat Service:**
```powershell
docker build -f backend/chatService/Dockerfile `
  -t $ECR_REGISTRY/$ECR_REPO/chat-service:latest .

docker push $ECR_REGISTRY/$ECR_REPO/chat-service:latest
```

## Verifying Images in ECR

### Via AWS CLI:
```powershell
# List repositories
aws ecr describe-repositories --region ap-south-1

# List images in repository
aws ecr describe-images --repository-name durga-streaming-app --region ap-south-1

# Get image details including digest and push date
aws ecr describe-images --repository-name durga-streaming-app --region ap-south-1 --query 'imageDetails[*].[imageTags,imagePushedAt]'
```

### Via AWS Console:
1. Go to AWS ECR Console
2. Navigate to `durga-streaming-app` repository
3. View all pushed images and their tags

## Image Tagging Strategy

Current strategy uses `latest` tag. For production, consider:

```powershell
# Tag by version
docker tag $ECR_REGISTRY/$ECR_REPO/frontend:latest $ECR_REGISTRY/$ECR_REPO/frontend:v1.0.0
docker push $ECR_REGISTRY/$ECR_REPO/frontend:v1.0.0

# Tag by date
docker tag $ECR_REGISTRY/$ECR_REPO/frontend:latest $ECR_REGISTRY/$ECR_REPO/frontend:2024-01-16
docker push $ECR_REGISTRY/$ECR_REPO/frontend:2024-01-16
```

## Troubleshooting

### Issue: ECR Login Failed
```
Error: No basic auth credentials
```
**Solution:**
```powershell
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.ap-south-1.amazonaws.com
```

### Issue: Repository Not Found
```
Error: repository not found
```
**Solution:** Create the repository first:
```powershell
aws ecr create-repository --repository-name durga-streaming-app --region ap-south-1
```

### Issue: Build Arguments Not Applied to Frontend
Ensure you're passing build arguments in the correct format for multi-stage builds. The script handles this automatically.

### Issue: Docker Daemon Not Running
**Solution:** Start Docker Desktop

### Issue: AWS Credentials Not Found
```powershell
# Configure AWS credentials
aws configure
```

## Next Steps

After pushing images to ECR:

1. **Create ECS Task Definitions** with the image URIs
2. **Set up ECS Service** for container orchestration
3. **Configure Application Load Balancer** for traffic distribution
4. **Set up CloudWatch** for monitoring and logs
5. **Enable Auto Scaling** based on metrics

## Image URIs for Deployment

Use these URIs in your deployment configurations:

```
Frontend:        <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/durga-streaming-app/frontend:latest
Auth Service:    <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/durga-streaming-app/auth-service:latest
Streaming Svc:   <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/durga-streaming-app/streaming-service:latest
Admin Service:   <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/durga-streaming-app/admin-service:latest
Chat Service:    <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com/durga-streaming-app/chat-service:latest
```

## Performance Optimization Tips

1. **Reduce Image Size**:
   - Use Alpine Linux for base images ✓ (already done)
   - Remove unnecessary dependencies
   - Use multi-stage builds ✓ (already done for frontend)

2. **Caching**:
   - Layer dependencies separately (COPY package.json before source code) ✓ (already done)
   - Leverage Docker layer caching for faster builds

3. **Security**:
   - Don't include `.env` files in images
   - Use specific base image tags (not `latest`)
   - Scan images for vulnerabilities

## Additional Resources

- [Docker Documentation](https://docs.docker.com)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
