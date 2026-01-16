# Quick Reference - Docker Images & ECR Deployment

## 🎯 Image URIs (Copy-Paste Ready)

### Auth Service
```
975050024946.dkr.ecr.eu-west-2.amazonaws.com/durga-streaming-app/auth-service:latest
```

### Streaming Service
```
975050024946.dkr.ecr.eu-west-2.amazonaws.com/durga-streaming-app/streaming-service:latest
```

### Admin Service
```
975050024946.dkr.ecr.eu-west-2.amazonaws.com/durga-streaming-app/admin-service:latest
```

### Chat Service
```
975050024946.dkr.ecr.eu-west-2.amazonaws.com/durga-streaming-app/chat-service:latest
```

### Frontend
```
975050024946.dkr.ecr.eu-west-2.amazonaws.com/durga-streaming-app/frontend:latest
```

## 🔐 ECR Login

```powershell
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin 975050024946.dkr.ecr.eu-west-2.amazonaws.com
```

## 📦 Image Info

| Service | Port | Size | Type |
|---------|------|------|------|
| auth-service | 3001 | 55.97 MB | Node.js |
| streaming-service | 3002 | 56.29 MB | Node.js |
| admin-service | 3003 | 55.58 MB | Node.js |
| chat-service | 3004 | 53.71 MB | Node.js |
| frontend | 80 | 21.93 MB | Nginx |

## 🚀 Rebuild & Push

```powershell
./build-and-push-to-ecr.ps1
```

## 📚 Documentation

- **DOCKER_BUILD_GUIDE.md** - Detailed build instructions
- **ECR_DEPLOYMENT_SUMMARY.md** - Complete deployment guide
- **build-and-push-to-ecr.ps1** - Automated build script

## 🔍 Verify Images

```powershell
# List all repositories
aws ecr describe-repositories --region eu-west-2 --query 'repositories[?contains(repositoryName, `durga-streaming-app`)].repositoryName'

# List images in a repository
aws ecr describe-images --repository-name durga-streaming-app/auth-service --region eu-west-2
```

## ⚙️ Environment Variables (Frontend Build)

```env
REACT_APP_AUTH_API_URL=https://your-domain.com/auth
REACT_APP_STREAMING_API_URL=https://your-domain.com/streaming
REACT_APP_STREAMING_PUBLIC_URL=https://your-domain.com
REACT_APP_ADMIN_API_URL=https://your-domain.com/admin
REACT_APP_CHAT_API_URL=https://your-domain.com/chat
REACT_APP_CHAT_SOCKET_URL=https://your-domain.com
```

## 📋 AWS Credentials

- **Region**: eu-west-2
- **Account ID**: 975050024946
- **Registry**: 975050024946.dkr.ecr.eu-west-2.amazonaws.com

---

**Status**: ✅ All 5 services containerized and deployed to ECR  
**Total Size**: ~243 MB  
**Date**: January 16, 2026
