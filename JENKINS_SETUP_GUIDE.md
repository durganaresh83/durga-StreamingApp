# Jenkins CI/CD Setup Guide for MERN Streaming App

## Table of Contents
1. [EC2 Instance Setup](#ec2-instance-setup)
2. [Jenkins Installation](#jenkins-installation)
3. [Jenkins Configuration](#jenkins-configuration)
4. [Pipeline Creation](#pipeline-creation)
5. [GitHub Integration](#github-integration)
6. [ECR Integration](#ecr-integration)
7. [Webhook Configuration](#webhook-configuration)
8. [Troubleshooting](#troubleshooting)

---

## EC2 Instance Setup

### Prerequisites
- AWS Account with EC2 access
- EC2 key pair (durga-windows.pem)
- Security group with ports 8080 (Jenkins) open

### 1. Connect to EC2 Instance

Using the provided PEM file:

```powershell
# Windows PowerShell
$KeyPath = "C:\path\to\durga-windows.pem"

# For Amazon Linux/Ubuntu:
# First, convert PEM to PPK if needed for PuTTY, or use WSL/Git Bash

# Using AWS Systems Manager (Easier - no SSH needed)
aws ssm start-session --target i-0a4d87a45f3ad38ee --region eu-west-2

# Or SSH directly (requires SSH client):
ssh -i durga-windows.pem ec2-user@YOUR_EC2_PUBLIC_IP
```

### 2. EC2 Security Group Configuration

Ensure your security group allows:
- **Inbound Port 8080**: Jenkins Web UI (from your IP or 0.0.0.0/0 for testing)
- **Inbound Port 22**: SSH (for administration)
- **Outbound All**: For Docker pulls and Git clones

```bash
# AWS CLI command to add inbound rule
aws ec2 authorize-security-group-ingress \
    --group-id sg-xxxxxxxx \
    --protocol tcp \
    --port 8080 \
    --cidr 0.0.0.0/0 \
    --region eu-west-2
```

---

## Jenkins Installation

### Step 1: Upload and Run Installation Script

```bash
# On your local machine, upload the script to EC2
scp -i durga-windows.pem jenkins-setup.sh ec2-user@YOUR_EC2_PUBLIC_IP:/tmp/

# SSH into EC2 and run the script
ssh -i durga-windows.pem ec2-user@YOUR_EC2_PUBLIC_IP

# On EC2 instance:
sudo bash /tmp/jenkins-setup.sh
```

### Step 2: Monitor Installation

The script will:
1. Update system packages
2. Install Java 17
3. Add Jenkins repository
4. Install Jenkins
5. Install Docker
6. Configure Jenkins user for Docker access
7. Install Git and AWS CLI
8. Install Node.js and npm

### Step 3: Get Initial Admin Password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Copy this password - you'll need it in the next step.

---

## Jenkins Configuration

### Step 1: Initial Setup Wizard

1. Open browser: `http://YOUR_EC2_PUBLIC_IP:8080`
2. Paste the initial admin password
3. Click "Continue"

### Step 2: Install Plugins

Select **"Install suggested plugins"** - this includes:
- Pipeline plugin
- Git plugin
- AWS SDK plugin
- Docker plugin
- Blue Ocean (Optional - modern UI)

**Wait for plugins to finish installing (~5-10 minutes)**

### Step 3: Create First Admin User

1. Click "Create First Admin User"
2. Fill in details:
   - Username: `admin`
   - Password: (strong password)
   - Full Name: Your Name
   - Email: your-email@example.com

### Step 4: Jenkins URL Configuration

- Jenkins URL: `http://YOUR_EC2_PUBLIC_IP:8080/`
- Click "Save and Continue"
- Click "Start using Jenkins"

### Step 5: Install Additional Plugins

Go to **Manage Jenkins** → **Manage Plugins** → **Available**

Search and install:
1. **GitHub Integration Plugin** - For GitHub webhooks
2. **Pipeline: GitHub Groovy Libraries** - For shared pipeline libraries
3. **CloudBees Docker Build and Publish** - For Docker operations
4. **Docker Pipeline** - For Docker in pipelines
5. **Amazon ECR Plugin** - For ECR integration
6. **AWS Credentials Plugin** - For AWS authentication

---

## Jenkins Credentials Setup

### Add GitHub Credentials

1. Go to **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. Click **Add Credentials**
3. Fill in:
   - Kind: **Username with password**
   - Username: Your GitHub username
   - Password: Your GitHub **Personal Access Token**
     - Generate at: https://github.com/settings/tokens
     - Scopes needed: `repo`, `admin:repo_hook`
   - ID: `github-credentials`
   - Description: GitHub Credentials for durga-streaming-app
4. Click **Create**

### Add AWS Credentials

1. Go to **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. Click **Add Credentials**
3. Fill in:
   - Kind: **AWS Credentials**
   - Access Key ID: Your AWS Access Key
   - Secret Access Key: Your AWS Secret Key
   - ID: `aws-credentials`
   - Description: AWS Credentials for ECR access
4. Click **Create**

### Configure AWS Region

1. Go to **Manage Jenkins** → **Configure System**
2. Scroll to **AWS Configuration**
3. Set **AWS Region**: `eu-west-2`
4. Click **Save**

---

## Pipeline Creation

### Method 1: Create Multibranch Pipeline (Recommended)

1. Click **New Item** on Jenkins dashboard
2. Enter name: `durga-streaming-app`
3. Select **Multibranch Pipeline**
4. Click **OK**

**Configure:**
- **Branch Sources**: Click **Add source** → **GitHub**
  - Credentials: Select `github-credentials`
  - Repository HTTPS URL: `https://github.com/durganaresh83/durga-StreamingApp.git`
  - Behaviors: Auto-discover branches and PRs

- **Build Configuration**:
  - Mode: **by Jenkinsfile**
  - Script path: `Jenkinsfile`

- **Scan Triggers**:
  - Check **Periodically if not otherwise run**
  - Interval: `1 hour`

- Click **Save**

### Method 2: Create Declarative Pipeline Job

1. Click **New Item**
2. Enter name: `durga-streaming-app-build`
3. Select **Pipeline**
4. Click **OK**

**Configure:**
- **Pipeline**:
  - Definition: **Pipeline script from SCM**
  - SCM: **Git**
  - Repository URL: `https://github.com/durganaresh83/durga-StreamingApp.git`
  - Credentials: `github-credentials`
  - Branch Specifier: `*/develop`
  - Script Path: `Jenkinsfile`

- **Build Triggers**:
  - Check **GitHub hook trigger for GITScm polling**

- Click **Save**

---

## GitHub Integration

### Step 1: Create GitHub Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click **Generate new token** → **Generate new token (classic)**
3. Name: `Jenkins-CI`
4. Scopes:
   - `repo` (Full control)
   - `admin:repo_hook` (Hook access)
5. Click **Generate token**
6. Copy the token (you won't see it again!)

### Step 2: Add Jenkins GitHub App (Webhook)

1. Go to your GitHub repository
2. Settings → **Webhooks** → **Add webhook**
3. Fill in:
   - **Payload URL**: `http://YOUR_EC2_PUBLIC_IP:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Which events would you like to trigger this webhook?**:
     - Select **Push events**
     - Select **Pull requests**
   - **Active**: ✓ Check this
4. Click **Add webhook**

### Step 3: Verify Webhook

1. You should see a green ✓ next to the webhook
2. Recent Deliveries should show successful deliveries

---

## ECR Integration

### Step 1: Create IAM User for Jenkins (Recommended)

```bash
# Create IAM user
aws iam create-user --user-name jenkins-ecr-user

# Create access keys
aws iam create-access-key --user-name jenkins-ecr-user

# Attach ECR policy
aws iam attach-user-policy \
    --user-name jenkins-ecr-user \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

### Step 2: Add AWS Credentials to Jenkins

Already done in the "Credentials Setup" section above.

### Step 3: Configure Docker in Jenkinsfile

The provided Jenkinsfile already includes:
- ECR login
- Image building
- Image pushing
- Image cleanup

### Step 4: Test ECR Push

Create a test pipeline run:
1. Go to your pipeline job
2. Click **Build Now** (or wait for webhook trigger)
3. Check **Console Output** for Docker build/push logs
4. Verify images in AWS ECR:

```bash
aws ecr describe-images \
    --repository-name durga-streaming-app/auth-service \
    --region eu-west-2
```

---

## Webhook Configuration

### Automatic Trigger on Git Push

With the webhook configured:
- Every push to `develop` branch triggers a build
- Every pull request triggers a build
- Builds run automatically without manual intervention

### Manual Build Trigger

1. Go to pipeline job
2. Click **Build Now** with parameters:
   - **BUILD_SERVICES**: Select which service(s) to build
   - **PUSH_TO_ECR**: true/false
   - **USE_LATEST_TAG**: true/false

### Scheduled Builds (Optional)

To rebuild periodically:
1. Go to pipeline configuration
2. Under **Build Triggers**, enable **Poll SCM**
3. Schedule: `H 2 * * *` (2 AM daily)

---

## Environment Variables for Frontend Build

Set these Jenkins credentials/parameters:

1. Go to **Manage Jenkins** → **Configure System**
2. Under **Global Properties**, check **Environment variables**
3. Add:

```
REACT_APP_AUTH_API_URL=https://api.yourdomain.com/auth
REACT_APP_STREAMING_API_URL=https://api.yourdomain.com/streaming
REACT_APP_STREAMING_PUBLIC_URL=https://api.yourdomain.com
REACT_APP_ADMIN_API_URL=https://api.yourdomain.com/admin
REACT_APP_CHAT_API_URL=https://api.yourdomain.com/chat
REACT_APP_CHAT_SOCKET_URL=https://api.yourdomain.com
```

---

## Jenkins Pipeline Features

### Build Parameters

The Jenkinsfile supports:
1. **BUILD_SERVICES**: Select which service to build (all, auth-service, streaming-service, admin-service, chat-service, frontend)
2. **PUSH_TO_ECR**: Whether to push images to ECR
3. **USE_LATEST_TAG**: Whether to also tag as 'latest'

### Build Numbers & Tagging

Images are tagged with:
- **Build number** (e.g., `45-abc1234`)
- **Latest tag** (optional)
- **Git commit SHA** (7 characters)

Example image URI:
```
975050024946.dkr.ecr.eu-west-2.amazonaws.com/durga-streaming-app/auth-service:45-abc1234
```

### Pipeline Stages

1. **Checkout** - Clone repository
2. **Initialize** - Verify environment
3. **ECR Login** - Authenticate to ECR
4. **Build Services** - Build Docker images
5. **Push to ECR** - Push images
6. **Cleanup** - Remove old images

---

## Monitoring & Logs

### View Build Logs

1. Click on pipeline job
2. Click on build number (e.g., #45)
3. Click **Console Output**
4. Search for stages or errors

### Blue Ocean (Optional Modern UI)

1. Install **Blue Ocean** plugin
2. Click **Open Blue Ocean** on pipeline job
3. See visual build pipeline

### Jenkins System Logs

```bash
# SSH into EC2
ssh -i durga-windows.pem ec2-user@YOUR_EC2_PUBLIC_IP

# View Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# View Docker logs
sudo journalctl -u docker -f
```

---

## Troubleshooting

### Issue: "Pipeline cannot be loaded"

**Solution**: Ensure:
- Jenkinsfile exists in repository root
- GitHub credentials are correct
- Repository URL is accessible

### Issue: "Docker command not found"

**Solution**: 
```bash
# Jenkins user needs Docker access
sudo usermod -a -G docker jenkins
sudo systemctl restart jenkins
```

### Issue: "Cannot push to ECR"

**Solution**:
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Verify ECR login
aws ecr get-login-password --region eu-west-2 | \
  docker login --username AWS --password-stdin 975050024946.dkr.ecr.eu-west-2.amazonaws.com

# Check IAM permissions for jenkins-ecr-user
aws iam get-user --user-name jenkins-ecr-user
```

### Issue: "Git clone fails"

**Solution**:
- Verify GitHub credentials in Jenkins
- Ensure repository is accessible
- Check SSH keys or Personal Access Token

### Issue: "Webhook not triggered"

**Solution**:
1. Check GitHub webhook delivery logs
2. Verify Jenkins URL is publicly accessible
3. Check firewall/security group allows inbound on port 8080

### Issue: "Jenkins takes too long to start"

**Solution**:
```bash
# Increase heap size for Jenkins
sudo vim /etc/sysconfig/jenkins

# Find JENKINS_JAVA_OPTIONS and set:
JENKINS_JAVA_OPTIONS="-Xmx1024m -Xms512m"

# Restart Jenkins
sudo systemctl restart jenkins
```

---

## Performance Optimization

### Docker Layer Caching

The Jenkinsfile leverages Docker layer caching:
- Dependencies are copied first
- Source code copied after
- Faster builds on subsequent runs

### Parallel Builds

Jenkins automatically runs multiple builds in parallel if resources allow.

To increase parallel builds:
1. **Manage Jenkins** → **Configure System**
2. Under **# of executors**: Change from 2 to higher number (4-8 recommended for t3.medium)
3. Click **Save**

### Cleanup Old Builds

The pipeline automatically cleans old Docker images:
- Removes dangling images
- Keeps only recent images

To disable automatic cleanup, comment out the **Cleanup** stage in Jenkinsfile.

---

## Next Steps

1. **Deploy to ECS**: Use Jenkins to deploy images to ECS services
2. **Add Testing**: Add unit tests and linting to pipeline
3. **Code Quality**: Integrate SonarQube for code analysis
4. **Notifications**: Add Slack/email notifications for build status
5. **Secrets Management**: Use AWS Secrets Manager for sensitive data

---

## Useful Commands

```bash
# SSH to EC2
ssh -i durga-windows.pem ec2-user@YOUR_EC2_PUBLIC_IP

# Check Jenkins status
sudo systemctl status jenkins

# View Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Restart Jenkins
sudo systemctl restart jenkins

# Check Docker status
sudo systemctl status docker

# View running containers
docker ps

# View Jenkins workspace
ls -la /var/lib/jenkins/workspace/

# Clear Jenkins cache
sudo rm -rf /var/lib/jenkins/workspace/*
```

---

## Security Best Practices

1. **Change Jenkins Admin Password**: Do this immediately after initial setup
2. **Use HTTPS**: Configure nginx reverse proxy with SSL
3. **Restrict Jenkins Access**: Use security group or firewall rules
4. **Rotate Credentials**: Regularly rotate AWS keys and GitHub tokens
5. **Enable Audit Logs**: Track all Jenkins activities
6. **Use IAM Roles**: Instead of access keys, use EC2 IAM roles for Jenkins
7. **Secure Secrets**: Store sensitive data in Jenkins credentials, not in code

---

## Summary

You now have:
- ✅ Jenkins installed and running
- ✅ Pipeline configured for building/pushing Docker images
- ✅ GitHub webhook integration for automatic triggers
- ✅ ECR integration for pushing images
- ✅ Build parameters for flexible job execution
- ✅ Monitoring and logging setup

**Status**: Ready for automated CI/CD builds!
