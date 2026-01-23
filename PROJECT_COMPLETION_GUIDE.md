# Durga Streaming App - Complete CI/CD & Kubernetes Deployment Guide

**Project Status**: ✅ COMPLETE  
**Last Updated**: January 23, 2026  
**Version**: 1.0.0

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Infrastructure Summary](#infrastructure-summary)
4. [CI/CD Pipeline](#cicd-pipeline)
5. [Kubernetes Deployment](#kubernetes-deployment)
6. [Quick Start Guide](#quick-start-guide)
7. [Troubleshooting](#troubleshooting)
8. [Cost Analysis](#cost-analysis)
9. [Team & Support](#team--support)

---

## Project Overview

**Durga Streaming App** is a full-stack MERN (MongoDB, Express, React, Node.js) microservices application with complete:
- ✅ CI/CD pipeline (Jenkins + GitHub)
- ✅ Containerization (Docker)
- ✅ Image registry (AWS ECR)
- ✅ Container orchestration (Kubernetes on EKS)
- ✅ Infrastructure as Code (Helm Charts)

### Tech Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Frontend | React | Latest |
| Backend | Node.js + Express | 18+ |
| Database | MongoDB | 6 |
| Container Runtime | Docker | 25.0.14 |
| CI/CD | Jenkins | 2.528.3 |
| Container Orchestration | Kubernetes (EKS) | 1.28 |
| Package Manager | Helm | 3+ |
| Cloud Provider | AWS | eu-west-2 |

### Microservices

1. **Auth Service** - User authentication and authorization
2. **Streaming Service** - Video streaming and management
3. **Admin Service** - Administrative operations
4. **Chat Service** - Real-time chat functionality
5. **Frontend** - React-based UI

---

## Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Internet Users                          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    AWS Route 53 (DNS)                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│         AWS Application Load Balancer (ALB)                 │
│              streaming.example.com:80/443                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              AWS EKS Cluster (Kubernetes)                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Namespace: durga-streaming                   │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │                                                        │  │
│  │  Frontend Pod(s)      Auth Service(s)                 │  │
│  │  Streaming Service(s) Admin Service(s)                │  │
│  │  Chat Service(s)      MongoDB Pod                     │  │
│  │                                                        │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │  Persistent Volume (EBS) - MongoDB Storage    │  │  │
│  │  │  - 10GB gp2 storage                           │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  │                                                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Node Pool: 3 × t3.medium EC2 instances                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### CI/CD Pipeline Architecture

```
┌──────────────────┐
│   Developer      │
│   (Git Commit)   │
└────────┬─────────┘
         │
         ↓
┌──────────────────────────────────────┐
│    GitHub (durganaresh83/         │
│    durga-StreamingApp)             │
│    Branch: develop                 │
└────────┬─────────────────────────────┘
         │
         │ Webhook Trigger
         ↓
┌──────────────────────────────────────┐
│  Jenkins Pipeline (Multibranch)      │
│  URL: http://3.10.52.203:8080        │
├──────────────────────────────────────┤
│ Stage 1: Checkout                   │
│ Stage 2: Initialize                 │
│ Stage 3: ECR Login                  │
│ Stage 4-8: Build 5 Services         │
│ Stage 9: Push to ECR                │
│ Stage 10: Cleanup                   │
└────────┬─────────────────────────────┘
         │
         ↓
┌──────────────────────────────────────┐
│  AWS ECR (Elastic Container        │
│  Registry)                           │
│  eu-west-2.amazonaws.com             │
│                                      │
│  • auth-service:latest              │
│  • streaming-service:latest         │
│  • admin-service:latest             │
│  • chat-service:latest              │
│  • frontend:latest                  │
└──────────────────────────────────────┘
```

---

## Infrastructure Summary

### AWS Resources

| Service | Resource | Configuration |
|---------|----------|----------------|
| **EC2** | Jenkins Server | t3.medium, 50GB SSD, public IP |
| **EKS** | Kubernetes Cluster | 1.28, 3 nodes (t3.medium) |
| **ECR** | Container Registry | 5 repositories, eu-west-2 |
| **EBS** | Storage | 10GB gp2 (MongoDB PVC) |
| **ALB** | Load Balancer | Application Load Balancer |
| **IAM** | Identity | Service accounts, roles |

### Jenkins Server Details

- **Instance ID**: i-0a88cd9cc156659b8
- **Instance Type**: t3.medium (2 vCPU, 4GB RAM)
- **Public IP**: 3.10.52.203 (dynamic, may change after reboot)
- **Region**: eu-west-2 (London)
- **OS**: Amazon Linux 2
- **Storage**: 50GB EBS (gp2)
- **Jenkins Version**: 2.528.3
- **Java**: OpenJDK 17 (Amazon Corretto)
- **Docker**: 25.0.14
- **Git**: 2.47.3
- **AWS CLI**: v1

### Git Setup

- **Repository**: https://github.com/durganaresh83/durga-StreamingApp
- **Branch**: develop
- **Access Method**: Personal Access Token (github-token)
- **Webhook**: ✅ Configured and verified
- **Auto-trigger**: ✅ On commits

---

## CI/CD Pipeline

### Pipeline Overview

The Jenkins pipeline automates:

1. **Code Checkout** - Pull latest code from GitHub
2. **Environment Setup** - Initialize build variables
3. **Docker Build** - Build 5 microservice images
4. **Registry Login** - Authenticate with AWS ECR
5. **Image Push** - Push images to ECR
6. **Tagging** - Tag images with build number and commit SHA

### Pipeline Stages

```
┌─────────────────────────┐
│  1. Checkout (GitHub)   │
│  ✓ Git clone            │
│  ✓ Branch: develop      │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│  2. Initialize          │
│  ✓ Docker version       │
│  ✓ AWS credentials      │
│  ✓ Build variables      │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│  3. ECR Login           │
│  ✓ AWS authentication   │
│  ✓ Docker login         │
└──────────┬──────────────┘
           ↓
┌──────────────────────────────────────┐
│  4-8. Parallel Build Services        │
│  ┌──────────────────────────────────┐│
│  │ ✓ Auth Service                  ││
│  │ ✓ Streaming Service             ││
│  │ ✓ Admin Service                 ││
│  │ ✓ Chat Service                  ││
│  │ ✓ Frontend (React + Nginx)      ││
│  └──────────────────────────────────┘│
└──────────┬───────────────────────────┘
           ↓
┌─────────────────────────┐
│  9. Push to ECR         │
│  ✓ All images tagged    │
│  ✓ Latest + Build # tag │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│  10. Cleanup            │
│  ✓ Docker cleanup       │
│  ✓ Build artifacts      │
└──────────┬──────────────┘
           ↓
┌─────────────────────────┐
│  ✅ SUCCESS NOTIFICATION│
│  GitHub + Email         │
└─────────────────────────┘
```

### Build Artifacts

Each build produces:
- 5 Docker images (one per service)
- Tagged with: `{BUILD_NUMBER}-{COMMIT_SHA}`
- Also tagged as: `latest`
- Pushed to ECR registry

### AWS Credentials Management

- **Location**: `/var/lib/jenkins/.aws/credentials`
- **File Permissions**: 600 (read-write for jenkins user only)
- **Owner**: jenkins:jenkins
- **Region Config**: `/var/lib/jenkins/.aws/config`
- **Rotation**: Manual (update credentials file + restart Jenkins)

---

## Kubernetes Deployment

### Helm Chart Structure

```
helm/durga-streaming/
├── Chart.yaml                    # Chart metadata
├── values.yaml                   # Default configuration
└── templates/
    ├── namespace.yaml            # Kubernetes namespace
    ├── serviceaccount.yaml       # RBAC service account
    ├── configmap.yaml            # Environment variables
    ├── mongodb.yaml              # Database deployment
    ├── auth-service.yaml         # Auth service + HPA
    ├── frontend.yaml             # Frontend deployment + HPA
    ├── ingress.yaml              # AWS ALB ingress
    └── pdb.yaml                  # Pod Disruption Budget
```

### Service Deployment Details

#### Frontend
- **Image**: `975050024946.dkr.ecr.eu-west-2.amazonaws.com/durga-streaming-app/frontend:latest`
- **Replicas**: 2-10 (auto-scaled)
- **Port**: 80 (HTTP)
- **Resources**: 64-128Mi memory, 50-200m CPU
- **Type**: ClusterIP Service

#### Auth Service
- **Image**: `975050024946.dkr.ecr.eu-west-2.amazonaws.com/durga-streaming-app/auth-service:latest`
- **Replicas**: 2-10 (auto-scaled)
- **Port**: 3001
- **Resources**: 128-256Mi memory, 100-500m CPU
- **Health Check**: `/api/health`

#### Streaming Service
- **Image**: `975050024946.dkr.ecr.eu-west-2.amazonaws.com/durga-streaming-app/streaming-service:latest`
- **Replicas**: 2-10 (auto-scaled)
- **Port**: 3002
- **Resources**: 256-512Mi memory, 200m-1000m CPU
- **Database**: MongoDB at `mongodb.durga-streaming.svc.cluster.local:27017`

#### MongoDB
- **Image**: mongo:6
- **Replicas**: 1 (stateful)
- **Port**: 27017
- **Storage**: 10GB EBS (gp2)
- **Persistence**: PersistentVolumeClaim

### Networking

- **Ingress Controller**: AWS ALB (Application Load Balancer)
- **DNS**: Route 53 (configure separately)
- **TLS**: Can be configured in values.yaml
- **Service Discovery**: Kubernetes DNS
- **Network Policies**: Disabled by default (can be enabled)

### High Availability

- **Multi-node Cluster**: 3 nodes (distribute replicas)
- **Pod Replicas**: Min 2, auto-scale to 10
- **Pod Disruption Budgets**: Prevent service interruption during node updates
- **Health Checks**: Liveness and readiness probes
- **Resource Limits**: CPU and memory constraints

---

## Quick Start Guide

### Prerequisites

#### Windows
```powershell
# Install tools
choco install aws-cli eksctl kubernetes-cli kubernetes-helm git

# Verify installation
aws --version
eksctl version
kubectl version --client
helm version
git --version
```

#### macOS
```bash
# Install tools
brew install awscli eksctl kubectl helm git

# Verify installation
aws --version
eksctl version
kubectl version --client
helm version
git --version
```

#### Linux
```bash
# See EKS_DEPLOYMENT_GUIDE.md for detailed instructions
```

### Step 1: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: eu-west-2
# Default output format: json
```

### Step 2: Create EKS Cluster

#### Option A: Using PowerShell Script (Easiest)
```powershell
cd <path-to-repo>
.\eks-cluster-setup.ps1 -ClusterName "durga-streaming-app" `
  -Region "eu-west-2" `
  -NodeCount 3 `
  -NodeType "t3.medium"

# This takes 15-20 minutes
```

#### Option B: Manual with eksctl
```bash
eksctl create cluster \
  --name durga-streaming-app \
  --region eu-west-2 \
  --nodes 3 \
  --node-type t3.medium \
  --version 1.28 \
  --managed

# This takes 15-20 minutes
```

### Step 3: Verify Cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --region eu-west-2 --name durga-streaming-app

# Verify connectivity
kubectl cluster-info
kubectl get nodes

# Expected output:
# NAME                                           STATUS   ROLES    AGE
# ip-192-168-xx-xx.eu-west-2.compute.internal   Ready    <none>   5m
# ip-192-168-xx-xx.eu-west-2.compute.internal   Ready    <none>   5m
# ip-192-168-xx-xx.eu-west-2.compute.internal   Ready    <none>   5m
```

### Step 4: Create Secrets

```bash
# Create namespace
kubectl create namespace durga-streaming

# Create database secret
kubectl create secret generic mongodb-secret \
  -n durga-streaming \
  --from-literal=root-password='changeme-in-production'

# Create application secrets
kubectl create secret generic app-secrets \
  -n durga-streaming \
  --from-literal=JWT_SECRET='your-jwt-secret-key-here' \
  --from-literal=AWS_ACCESS_KEY_ID='AKIA6GBMCU7ZOFFYUQNG' \
  --from-literal=AWS_SECRET_ACCESS_KEY='your-secret-key-here'
```

### Step 5: Deploy Application

```bash
# Navigate to Helm chart
cd helm/durga-streaming

# Install release
helm install durga-streaming . \
  -n durga-streaming \
  --values values.yaml

# Verify deployment
kubectl get pods -n durga-streaming

# Expected output (after 2-3 minutes):
# NAME                              READY   STATUS    RESTARTS   AGE
# auth-service-xxxxx                1/1     Running   0          2m
# streaming-service-xxxxx           1/1     Running   0          2m
# admin-service-xxxxx               1/1     Running   0          2m
# chat-service-xxxxx                1/1     Running   0          2m
# frontend-xxxxx                    1/1     Running   0          2m
# mongodb-xxxxx                     1/1     Running   0          2m
```

### Step 6: Get Load Balancer URL

```bash
# Get ingress URL
kubectl get ingress -n durga-streaming

# Get detailed ingress info
kubectl describe ingress durga-streaming-ingress -n durga-streaming

# Get the ALB endpoint and add DNS record
# Example: k8s-durgas-durgas-xxxxx-1234567890.eu-west-2.elb.amazonaws.com
```

### Step 7: Access Application

```
Frontend: http://<ALB-URL>
Auth API: http://<ALB-URL>/api/auth
Streaming: http://<ALB-URL>/api/streaming
Admin: http://<ALB-URL>/api/admin
Chat: http://<ALB-URL>/api/chat
```

---

## Post-Deployment Operations

### View Logs

```bash
# Frontend logs
kubectl logs -n durga-streaming -l app=frontend -f --all-containers

# Auth service logs
kubectl logs -n durga-streaming -l app=auth-service -f

# All pod logs
kubectl logs -n durga-streaming -f --all-containers=true
```

### Port Forwarding (Local Access)

```bash
# Frontend (localhost:3000)
kubectl port-forward -n durga-streaming svc/frontend 3000:80

# Auth service (localhost:3001)
kubectl port-forward -n durga-streaming svc/auth-service 3001:3001

# Streaming service (localhost:3002)
kubectl port-forward -n durga-streaming svc/streaming-service 3002:3002

# MongoDB (localhost:27017)
kubectl port-forward -n durga-streaming svc/mongodb 27017:27017
```

### Monitor Resources

```bash
# Pod resource usage
kubectl top pods -n durga-streaming

# Node resource usage
kubectl top nodes

# Watch pods
kubectl get pods -n durga-streaming --watch
```

### Update Deployment

```bash
# After pushing new images to ECR
helm upgrade durga-streaming . \
  -n durga-streaming \
  --values values.yaml \
  --set authService.image.tag=latest

# Or update all images
helm upgrade durga-streaming . \
  -n durga-streaming \
  --values values.yaml \
  --set "authService.image.tag=14-abc1234,streamingService.image.tag=14-abc1234"
```

### Rollback Deployment

```bash
# View release history
helm history durga-streaming -n durga-streaming

# Rollback to previous version
helm rollback durga-streaming -n durga-streaming

# Rollback to specific version
helm rollback durga-streaming 1 -n durga-streaming
```

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n durga-streaming

# Check pod logs
kubectl logs <pod-name> -n durga-streaming

# Check events
kubectl get events -n durga-streaming --sort-by='.lastTimestamp'
```

### Database Connection Issues

```bash
# Test MongoDB connectivity
kubectl run -it --rm debug --image=mongo:6 --restart=Never -n durga-streaming -- \
  mongo mongodb://mongodb:27017 --eval "db.adminCommand('ping')"
```

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n durga-streaming

# Check ingress configuration
kubectl get ingress -n durga-streaming -o yaml

# Test ALB health
kubectl get ingress -n durga-streaming -o wide
```

### Jenkins Build Failures

```bash
# Check Jenkins logs
ssh -i durga-windows.pem ec2-user@3.10.52.203 "sudo tail -f /var/log/jenkins/jenkins.log"

# Check AWS credentials
ssh -i durga-windows.pem ec2-user@3.10.52.203 "sudo cat /var/lib/jenkins/.aws/credentials"

# Verify ECR access
ssh -i durga-windows.pem ec2-user@3.10.52.203 "aws ecr list-repositories --region eu-west-2"
```

### Scaling Issues

```bash
# Check HPA status
kubectl get hpa -n durga-streaming

# Check HPA detailed status
kubectl describe hpa auth-service-hpa -n durga-streaming

# Check metrics server
kubectl get deployment metrics-server -n kube-system
```

---

## Cost Analysis

### Monthly AWS Costs

| Service | Unit | Quantity | Price | Total |
|---------|------|----------|-------|-------|
| **EKS Cluster** | Cluster | 1 | $73.00 | $73.00 |
| **EC2 Nodes** | t3.medium On-Demand | 3 | $30.32/mo | $90.96 |
| **EBS Storage** | 10GB gp2 | 1 | $1.00 | $1.00 |
| **Data Transfer** | GB (egress) | ~100 | $0.09 | $9.00 |
| **ALB** | Hour | 730 | $0.0225 | $16.43 |
| **ALB LCU** | LCU | ~10 | $0.006 | $60.00 |
| **Jenkins EC2** | t3.medium On-Demand | 1 | $30.32/mo | $30.32 |
| **Jenkins EBS** | 50GB gp2 | 1 | $5.00 | $5.00 |
| | | | **TOTAL** | **~$285.71** |

### Cost Optimization Strategies

1. **Use Spot Instances** (70% savings)
   ```bash
   eksctl create cluster ... --spot
   # Saves ~$64/month on compute
   ```

2. **Reserved Instances** (40% discount)
   - 1-year or 3-year commitment
   - Saves ~$45-90/month

3. **Scheduled Scaling**
   - Scale down during off-hours
   - Save ~$50-100/month

4. **Auto-scaling Tuning**
   - Optimize CPU/memory targets
   - Reduce unnecessary replicas

5. **Right-sizing Nodes**
   - Consider t3.small instead of t3.medium
   - Save ~$15/month per node

**Potential Optimized Cost**: ~$150-200/month with Spot Instances + Reserved Instances

---

## Repository Structure

```
durga-StreamingApp/
├── backend/
│   ├── authService/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── index.js
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── routes/
│   │   └── middleware/
│   ├── streamingService/
│   ├── adminService/
│   └── chatService/
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   ├── public/
│   └── src/
├── helm/
│   └── durga-streaming/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── docker-compose.yml         # Local development
├── Jenkinsfile                # CI/CD pipeline
├── eks-cluster-setup.ps1      # Cluster creation
├── deploy-to-eks.sh           # Quick deployment
├── start-services.ps1         # Local startup
├── .env                       # Environment variables (gitignored)
├── .gitignore                 # Updated with .env
├── EKS_DEPLOYMENT_GUIDE.md    # Detailed guide
├── LICENSE
└── README.md
```

---

## Team & Support

### Key Contacts

- **Project Owner**: Durga Naresh
- **Repository**: https://github.com/durganaresh83/durga-StreamingApp
- **AWS Account ID**: 975050024946
- **AWS Region**: eu-west-2 (London)

### Documentation

- **Complete Guide**: See `EKS_DEPLOYMENT_GUIDE.md`
- **Docker Compose Guide**: `docker-compose.yml` with start-services.ps1
- **Helm Reference**: `helm/durga-streaming/values.yaml`

### External Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [EKS Best Practices](https://docs.aws.amazon.com/eks/)
- [Helm Charts](https://helm.sh/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)

---

## Next Steps

1. ✅ **Completed**: CI/CD infrastructure (Jenkins + GitHub)
2. ✅ **Completed**: Containerization (Docker)
3. ✅ **Completed**: Container Registry (ECR)
4. ✅ **Completed**: Kubernetes Setup (EKS + Helm)
5. 🔄 **Next**: Create EKS cluster and deploy application
6. 🔄 **Future**: Add monitoring (Prometheus + Grafana)
7. 🔄 **Future**: Add logging (ELK Stack)
8. 🔄 **Future**: Add auto-scaling and load testing
9. 🔄 **Future**: Configure CI/CD to auto-deploy to EKS

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-23 | Initial release - Complete CI/CD and Kubernetes setup |

---

**Last Updated**: 2026-01-23  
**Project Status**: ✅ Complete (Ready for Deployment)  
**Maintained By**: DevOps Team
