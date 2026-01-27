# StreamingApp

Stream premium video content, host live watch parties, and manage your catalogue with a modern microservice architecture. The platform now ships with a production-ready admin portal, real-time chat, S3-backed adaptive streaming, and a redesigned cinematic frontend experience.

## Architecture

| Service | Port | Description |
| --- | --- | --- |
| `authService` | 3001 | User authentication, registration, JWT issuance |
| `streamingService` | 3002 | Video catalogue, S3 playback endpoints, public APIs |
| `adminService` | 3003 | Dedicated admin microservice for asset management and uploads |
| `chatService` | 3004 | Websocket + REST chat for live watch parties |
| `frontend` | 3000 | React SPA with revamped UI and integrated chat |
| `mongo` | 27017 | Shared MongoDB instance |

All backend services share common database models and utilities through `backend/common`.

## Environment Configuration

Create an `.env` for all services. All services accept the standard AWS credentials for S3 access.

# MongoDB Configuration <br>
`MONGO_DB=streamingapp`

# JWT Configuration <br>
`JWT_SECRET=your-super-secret-jwt-key-change-this-in-production`

# Client URLs <br>
`CLIENT_URLS=http://localhost:3000`

# AWS Configuration (Optional - for S3 uploads) <br>
`AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxxxxxxx` <br>
`AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxx` <br>
`AWS_REGION=eu-west-2` <br>
`AWS_S3_BUCKET=your-s3-bucket-name` <br>

# Service Port Configuration <br>
`AUTH_PORT=3001` <br>
`STREAMING_PORT=3002` <br>
`ADMIN_PORT=3003` <br>
`CHAT_PORT=3004` <br>

# Frontend API URLs <br>
`REACT_APP_AUTH_API_URL=http://localhost:3001/api` <br>
`REACT_APP_STREAMING_API_URL=http://localhost:3002/api` <br>
`REACT_APP_STREAMING_PUBLIC_URL=http://localhost:3002` <br>
`REACT_APP_ADMIN_API_URL=http://localhost:3003/api/admin` <br>
`REACT_APP_CHAT_API_URL=http://localhost:3004/api/chat` <br>
`REACT_APP_CHAT_SOCKET_URL=http://localhost:3004` <br>
```
# AWS CDN URL (if using CloudFront) <br>
AWS_CDN_URL= <br>

# Streaming Service Public URL <br>
`STREAMING_PUBLIC_URL=http://localhost:3002` <br>

# Step 2 - Prepare the MERN Application <>br
## Running with Docker Compose <br>

1. Populate the environment variables above (or rely on the defaults baked into `docker-compose.yml`).
2. Build and start the stack:
   ```bash
   docker-compose up --build
   ```
3. Navigate to `http://localhost:3000` for the web app.

The compose file provisions MongoDB plus all four Node.js microservices. S3 credentials are optional for local testing—you can still browse seeded metadata, but streaming requires valid S3 objects.

## Local Development

Install dependencies for each service:

```bash
# auth service
cd backend/authService && npm install

# streaming service
cd ../streamingService && npm install

# admin service
cd ../adminService && npm install

# chat service
cd ../chatService && npm install

# frontend
cd ../../frontend && npm install
```

Run the services (in separate terminals) after starting MongoDB:

```bash
cd backend/authService && npm run dev
cd backend/streamingService && npm run dev
cd backend/adminService && npm run dev
cd backend/chatService && npm run dev
cd frontend && npm start
```
# Step 3 - AWS Environment setup <br>
1. Install the AWS CLI <br>
2. Configure the AWS CLI for all AWS CLI Commands <br>

# Step 4 - Continuous Integration (CI) using Jenkins
### 1. Connect to EC2 and Install Jenkins

```powershell
# On your Windows machine
# Run the helper script
.\jenkins-setup-helper.ps1

# Or manually using AWS Systems Manager:
aws ssm start-session --target i-0a4d87a45f3ad38ee --region eu-west-2

# On EC2 instance, run:
curl -fsSL https://raw.githubusercontent.com/durganaresh83/durga-StreamingApp/develop/jenkins-setup.sh | sudo bash

# Get initial password:
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 2. Complete Jenkins Web UI Setup

1. Open: `http://YOUR_EC2_PUBLIC_IP:8080`
2. Enter initial admin password
3. Install suggested plugins
4. Create admin user
5. Configure Jenkins URL

### 3. Add Credentials to Jenkins

**GitHub Credentials**:
```
Type: Username with password
Username: your-github-username
Password: your-github-token (from https://github.com/settings/tokens)
ID: github-credentials
```

**AWS Credentials**:
```
Type: AWS Credentials
Access Key ID: your-aws-access-key
Secret Access Key: your-aws-secret-key
ID: aws-credentials
```

### 4. Create Pipeline Job

**Option A: Multibranch Pipeline** (Recommended)
- Type: Multibranch Pipeline
- Branch Source: GitHub
- Repository: https://github.com/durganaresh83/durga-StreamingApp.git
- Script Path: Jenkinsfile
- Scan Triggers: Every hour

**Option B: Declarative Pipeline**
- Type: Pipeline
- Definition: Pipeline script from SCM
- SCM: Git
- Script Path: Jenkinsfile
- Build Trigger: GitHub hook trigger

### 5. Configure GitHub Webhook

1. Go to Repository Settings → Webhooks → Add webhook
2. **Payload URL**: `http://YOUR_EC2_PUBLIC_IP:8080/github-webhook/`
3. **Content type**: application/json
4. **Events**: Push events (and PR events if desired)
5. Click Add webhook

### 6. Test Pipeline

```bash
# Push a commit to trigger build
git add .
git commit -m "Test Jenkins webhook"
git push origin develop

# Check Jenkins for automatic build
# Open: http://YOUR_EC2_PUBLIC_IP:8080/job/durga-streaming-app/
```

## 🔍 Monitoring Builds

### View Build Progress

1. Jenkins Dashboard: `http://YOUR_EC2_PUBLIC_IP:8080`
2. Click job name → Click build number
3. View Console Output in real-time

### Check ECR Images

```bash
# List all images
aws ecr describe-images --repository-name durga-streaming-app/auth-service --region eu-west-2

# Get image details
aws ecr describe-images \
  --repository-name durga-streaming-app/auth-service \
  --region eu-west-2 \
  --query 'imageDetails[*].[imageTags[0], imageSizeInBytes, imagePushedAt]' \
  --output table
```
### On EC2 Instance to check the Jenkins service status

```bash
# Check Jenkins status
sudo systemctl status jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# View Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Docker commands
docker ps
docker images
docker logs <container-id>

# Workspace location
cd /var/lib/jenkins/workspace/durga-streaming-app

# Check disk space
df -h
```
---
# Step 5: Kubernetes Deployment (EKS)
### Step 1: Install Required Tools

#### On Windows (PowerShell):

```powershell
# Install AWS CLI v2
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

# Install eksctl
choco install eksctl

# Install kubectl
choco install kubernetes-cli

# Install Helm
choco install kubernetes-helm
```
### Step 2: Create EKS Cluster

#### Using PowerShell Script (Windows)

```powershell
cd <path-to-repo>
.\eks-cluster-setup.ps1 -ClusterName "durga-streaming-app" -Region "eu-west-2" -NodeCount 3 -NodeType "t3.medium"
```
### Step 3: Verify Cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --region eu-west-2 --name durga-streaming-app

# Verify cluster connectivity
kubectl cluster-info

# Check nodes
kubectl get nodes

# Expected output:
# NAME                                           STATUS   ROLES    AGE     VERSION
# ip-192-168-XX-XX.eu-west-2.compute.internal   Ready    <none>   10m     v1.28.x

### **Step 4: Install AWS Load Balancer Controller**

```bash
# Add AWS EKS Helm repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set cluster.name=durga-streaming-app \
  --set serviceAccount.create=true
```

### Step 5: Create Secrets for Application

```bash
# Create namespace
kubectl create namespace durga-streaming

# Create secrets for database and AWS credentials
kubectl create secret generic mongodb-secret \
  -n durga-streaming \
  --from-literal=root-password='changeme'

kubectl create secret generic app-secrets \
  -n durga-streaming \
  --from-literal=JWT_SECRET='your-jwt-secret-key' \
  --from-literal=AWS_ACCESS_KEY_ID='AKIA6GBMCU7ZOFFYUQNG' \
  --from-literal=AWS_SECRET_ACCESS_KEY='your-secret-key'
```

### Step 6: Deploy Application with Helm

```bash
# Navigate to helm chart directory
cd helm/durga-streaming

# Install Helm chart
helm install durga-streaming . \
  -n durga-streaming \
  --values values.yaml

# Verify deployment
kubectl get pods -n durga-streaming

# Expected output:
# NAME                              READY   STATUS    RESTARTS   AGE
# auth-service-xxx                  1/1     Running   0          2m
# streaming-service-xxx             1/1     Running   0          2m
# admin-service-xxx                 1/1     Running   0          2m
# chat-service-xxx                  1/1     Running   0          2m
# frontend-xxx                      1/1     Running   0          2m
# mongodb-xxx                       1/1     Running   0          2m

<img width="1862" height="762" alt="image" src="https://github.com/user-attachments/assets/dde11f1f-7936-459d-a9a3-88d287dd21c6" />


### Step 7: Post-Deployment
### Check Service Status

```bash
# Check all services
kubectl get svc -n durga-streaming

# Check ingress
kubectl get ingress -n durga-streaming

# Describe ingress (get load balancer URL)
kubectl describe ingress durga-streaming-ingress -n durga-streaming
```
### View Logs

```bash
# View auth service logs
kubectl logs -n durga-streaming -l app=auth-service --tail=100 -f

# View all service logs
kubectl logs -n durga-streaming --all-containers=true --tail=50 -f
```

### Port Forward for Local Testing

```bash
# Forward frontend to localhost:3000
kubectl port-forward -n durga-streaming svc/frontend 3000:80

# Forward auth service to localhost:3001
kubectl port-forward -n durga-streaming svc/auth-service 3001:3001

# Forward streaming service to localhost:3002
kubectl port-forward -n durga-streaming svc/streaming-service 3002:3002

### Step 6: Monitoring and Logging
### 1. CloudWatch Log Groups ✅

**Created Log Groups** (30-day retention):
```
/aws/eks/durga-streaming-app/cluster
/aws/eks/durga-streaming-app/pods
/aws/eks/durga-streaming-app/application
```
<img width="1582" height="380" alt="image" src="https://github.com/user-attachments/assets/fddf6bfb-2e9c-4e97-bcd8-01e30dce5317" />

### 2. Fluent Bit Log Aggregation ✅

**Deployment**: DaemonSet in `monitoring` namespace

**Features**:
- Collects container logs from all pods
- Collects systemd logs from nodes
- Kubernetes enrichment (pod name, namespace, labels, annotations)
- CRI log parsing
- Automatic forwarding to CloudWatch Logs

**Configuration** (`fluent-bit-config.yaml`) - Refer the fluent-bit-config.yaml <br>

### 3. CloudWatch Alarms & SNS ✅

**SNS Topic Created**:
```
arn:aws:sns:eu-west-2:975050024946:durga-streaming-alerts

<img width="1661" height="447" alt="image" src="https://github.com/user-attachments/assets/0ef24020-c9cb-497a-b361-3b03ef292e19" />

```

# **Testing**

### All services are deployed in EKS cluster with Helm charts <br>
```
<img width="1552" height="675" alt="image" src="https://github.com/user-attachments/assets/8c0177ef-501e-4570-9453-8efffe14deb5" />


Verify that both frontend and backend are functional and accessible.

<img width="1388" height="946" alt="image" src="https://github.com/user-attachments/assets/e251bfa7-8712-4c43-9ac2-2af698cc025d" />


## License

MIT © StreamFlix Team
