# Step 4: Continuous Integration (CI) with Jenkins - Setup Guide

## 📋 Overview

This guide provides everything needed to set up Jenkins CI/CD for the MERN Streaming App with:
- Automated Docker image building
- Pushing images to AWS ECR
- GitHub webhook integration for auto-triggers
- Jenkins pipeline configuration

## ⚠️ Important: EC2 Instance Setup

**DO NOT use shared instances!** Create a dedicated EC2 instance named `durga-streaming-app` for Jenkins.

### Current Instances in eu-west-2:
- ❌ i-0a4d87a45f3ad38ee - full-adish (NOT YOURS)
- ❓ i-0ec037ee18cfd32a7 - streaming-cluster-adi-standard-workers-Node
- ❓ i-0344225adf4402505 - streaming-cluster-adi-standard-workers-Node

## 🚀 Quick Start

### Option 1: Create New Instance (RECOMMENDED)

```powershell
# Run the automated EC2 creation script
.\create-jenkins-instance.ps1 -KeyName "your-key-pair-name"
```

See `EC2_JENKINS_INSTANCE_SETUP.md` for details.

### Option 2: Use Existing Instance

```powershell
# Setup Jenkins on an existing instance
.\jenkins-setup-helper.ps1 -InstanceName "your-instance-name"
```

## 📁 Files Included

| File | Purpose |
|------|---------|
| **Jenkinsfile** | Pipeline configuration (place in repo root) |
| **jenkins-setup.sh** | Automated Jenkins installation script |
| **jenkins-setup-helper.ps1** | Windows helper for setup |
| **create-jenkins-instance.ps1** | Automated EC2 + Jenkins setup |
| **JENKINS_SETUP_GUIDE.md** | Detailed setup documentation |
| **GITHUB_WEBHOOK_SETUP.md** | GitHub webhook configuration |
| **JENKINS_CI_REFERENCE.md** | Quick reference guide |
| **EC2_JENKINS_INSTANCE_SETUP.md** | EC2 instance creation guide |

## 🔧 Complete Setup Steps

### Step 1: Create Jenkins EC2 Instance

```powershell
# List your key pairs first
aws ec2 describe-key-pairs --region eu-west-2

# Create instance with your key pair
.\create-jenkins-instance.ps1 -KeyName "your-key-pair-name" -PemFilePath "your-key-file.pem"
```

**Output**: Instance ID and Public IP address

### Step 2: Install Jenkins

```bash
# SSH into your instance
ssh -i your-key-file.pem ec2-user@YOUR_PUBLIC_IP

# Run Jenkins setup (on EC2)
curl -fsSL https://raw.githubusercontent.com/durganaresh83/durga-StreamingApp/develop/jenkins-setup.sh | sudo bash

# Get initial password (after ~2 minutes)
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Step 3: Configure Jenkins Web UI

1. Open: `http://YOUR_PUBLIC_IP:8080`
2. Enter initial admin password
3. Install suggested plugins
4. Create admin user
5. Save Jenkins URL configuration

### Step 4: Add Credentials

**GitHub Credentials**:
- Go to Manage Jenkins → Credentials → System → Global credentials
- Add Credentials → Username with password
  - Username: Your GitHub username
  - Password: GitHub Personal Access Token
  - ID: `github-credentials`

**AWS Credentials**:
- Add Credentials → AWS Credentials
  - Access Key ID: Your AWS key
  - Secret Access Key: Your AWS secret
  - ID: `aws-credentials`

### Step 5: Create Pipeline Job

Option A: **Multibranch Pipeline** (Recommended)
- New Item → Multibranch Pipeline
- Branch Source: GitHub
- Repository: `https://github.com/durganaresh83/durga-StreamingApp.git`
- Script Path: `Jenkinsfile`

Option B: **Declarative Pipeline**
- New Item → Pipeline
- Pipeline → Pipeline script from SCM
- SCM: Git, Script Path: `Jenkinsfile`

### Step 6: Configure GitHub Webhook

1. Go to Repository Settings → Webhooks → Add webhook
2. **Payload URL**: `http://YOUR_PUBLIC_IP:8080/github-webhook/`
3. **Content type**: application/json
4. **Events**: Push events (and PR events if desired)
5. Click Add webhook

See `GITHUB_WEBHOOK_SETUP.md` for detailed webhook configuration.

### Step 7: Test the Pipeline

```bash
# Push a commit to trigger Jenkins
git add .
git commit -m "Test Jenkins webhook"
git push origin develop

# Check Jenkins dashboard for automatic build
# Open: http://YOUR_PUBLIC_IP:8080/job/durga-streaming-app/
```

## 📊 Pipeline Features

### Build Parameters
- **BUILD_SERVICES**: Choose which service(s) to build
- **PUSH_TO_ECR**: Whether to push to ECR
- **USE_LATEST_TAG**: Also tag as 'latest'

### Build Stages
1. **Checkout** - Clone repository
2. **Initialize** - Verify Docker
3. **ECR Login** - Authenticate
4. **Build Services** - Build Docker images
5. **Push to ECR** - Push images
6. **Cleanup** - Remove old images

### Image Naming
Images are tagged with:
- Build number + git commit SHA
- Example: `auth-service:45-abc1234`

## 🔐 Security Checklist

- ✅ Use dedicated EC2 instance
- ✅ Change Jenkins admin password
- ✅ Use strong GitHub tokens
- ✅ Rotate AWS credentials regularly
- ✅ Restrict security group access
- ✅ Enable Jenkins security
- ✅ Use SSL/TLS (optional but recommended)

## 📈 What's Happening in the Pipeline

### When you push code to GitHub:

1. **Webhook triggers** Jenkins build
2. **Code is checked out** from GitHub
3. **Docker images are built** for each service
4. **Images are pushed to ECR** with automatic tagging
5. **Build results** are displayed in Jenkins
6. **Logs are archived** for debugging

### Services Built:
- auth-service (Node.js + Express)
- streaming-service (Node.js + Express)
- admin-service (Node.js + Express)
- chat-service (Node.js + Socket.io)
- frontend (React + Nginx)

## 🛠️ Useful Commands

```bash
# SSH to EC2
ssh -i your-key-file.pem ec2-user@YOUR_PUBLIC_IP

# Check Jenkins status
sudo systemctl status jenkins

# View Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Restart Jenkins
sudo systemctl restart jenkins

# Check available images in ECR
aws ecr describe-images --repository-name durga-streaming-app/auth-service --region eu-west-2
```

## 📝 AWS Configuration Reference

- **AWS Account ID**: 975050024946
- **ECR Registry**: 975050024946.dkr.ecr.eu-west-2.amazonaws.com
- **Region**: eu-west-2 (London)
- **Repository**: durga-streaming-app

## 🐛 Troubleshooting

### Jenkins won't start?
```bash
sudo systemctl status jenkins
sudo journalctl -u jenkins -n 50
```

### Docker command not found?
```bash
sudo usermod -a -G docker jenkins
sudo systemctl restart jenkins
```

### Can't push to ECR?
```bash
# Verify credentials
aws sts get-caller-identity

# Verify ECR access
aws ecr describe-repositories --region eu-west-2
```

### Webhook not triggering builds?
1. Check GitHub webhook Recent Deliveries
2. Verify Jenkins URL is publicly accessible
3. Check Jenkins logs for errors
4. Manually redeliver webhook from GitHub

See `JENKINS_SETUP_GUIDE.md` for more troubleshooting.

## 📚 Documentation Structure

```
├── Jenkinsfile                          # Pipeline definition
├── JENKINS_SETUP_GUIDE.md              # Detailed setup guide
├── GITHUB_WEBHOOK_SETUP.md             # Webhook configuration
├── JENKINS_CI_REFERENCE.md             # Quick reference
├── EC2_JENKINS_INSTANCE_SETUP.md       # EC2 creation guide
├── jenkins-setup.sh                     # Installation script
├── jenkins-setup-helper.ps1             # Windows setup helper
└── create-jenkins-instance.ps1          # EC2 + Jenkins automation
```

## ✅ Implementation Checklist

- [ ] Create EC2 instance (durga-streaming-app)
- [ ] Run jenkins-setup.sh on EC2
- [ ] Access Jenkins web UI
- [ ] Install suggested plugins
- [ ] Create admin user
- [ ] Add GitHub credentials
- [ ] Add AWS credentials
- [ ] Create pipeline job
- [ ] Configure GitHub webhook
- [ ] Test pipeline with git push
- [ ] Verify images in ECR
- [ ] Set up monitoring (optional)

## 🎯 Next Steps

1. **Create and configure EC2 instance** ← START HERE
2. **Install and configure Jenkins**
3. **Set up GitHub credentials and webhook**
4. **Test end-to-end CI/CD pipeline**
5. Deploy to ECS (next step)

## 📞 Need Help?

1. Check detailed guides in documentation folder
2. Review Jenkins logs on EC2: `sudo tail -f /var/log/jenkins/jenkins.log`
3. Verify webhook delivery on GitHub: Settings → Webhooks → Recent Deliveries
4. Test AWS credentials: `aws sts get-caller-identity`

---

**Status**: Ready for Jenkins CI/CD Implementation  
**Created**: January 16, 2026  
**Last Updated**: January 16, 2026
