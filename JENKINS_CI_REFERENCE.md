# Jenkins CI/CD Quick Reference

## Key Information

### AWS Setup
- **AWS Account ID**: 975050024946
- **ECR Registry**: 975050024946.dkr.ecr.eu-west-2.amazonaws.com
- **ECR Repositories**: durga-streaming-app/[auth-service|streaming-service|admin-service|chat-service|frontend]
- **Region**: eu-west-2 (London)
- **EC2 Instance Name**: durga-streaming-app
- **EC2 Key File**: durga-windows.pem

### Jenkins URLs
- **Jenkins URL**: http://YOUR_EC2_PUBLIC_IP:8080
- **Jenkins Port**: 8080
- **Webhook URL**: http://YOUR_EC2_PUBLIC_IP:8080/github-webhook/

### GitHub Configuration
- **Repository**: https://github.com/durganaresh83/durga-StreamingApp.git
- **Default Branch**: develop
- **Jenkinsfile Path**: Jenkinsfile (repository root)

---

## 🚀 Quick Setup Steps

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

---

## 📋 Pipeline Build Parameters

When manually triggering builds:

| Parameter | Options | Default |
|-----------|---------|---------|
| BUILD_SERVICES | all, auth-service, streaming-service, admin-service, chat-service, frontend | all |
| PUSH_TO_ECR | true, false | true |
| USE_LATEST_TAG | true, false | true |

### Example Manual Build

```bash
# Build specific service
curl -X POST \
  "http://YOUR_EC2_PUBLIC_IP:8080/job/durga-streaming-app/buildWithParameters" \
  -u admin:your-jenkins-password \
  -d "BUILD_SERVICES=auth-service&PUSH_TO_ECR=true&USE_LATEST_TAG=true"
```

---

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

---

## 🐛 Troubleshooting

### Jenkins Won't Start

```bash
ssh -i durga-windows.pem ec2-user@YOUR_EC2_PUBLIC_IP
sudo systemctl status jenkins
sudo journalctl -u jenkins -n 50
```

### Build Fails - Docker Not Found

```bash
# Fix: Add Jenkins to docker group
sudo usermod -a -G docker jenkins
sudo systemctl restart jenkins
```

### Build Fails - Cannot Push to ECR

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Verify ECR access
aws ecr describe-repositories --region eu-west-2

# Check IAM permissions
aws iam get-user
```

### Webhook Not Triggered

1. Check GitHub webhook Recent Deliveries
2. Verify Jenkins is publicly accessible
3. Check Jenkins logs: `sudo tail -f /var/log/jenkins/jenkins.log`
4. Manually redeliver webhook from GitHub

### Build Slow

1. Increase EC2 instance size (t3.large or t3.xlarge)
2. Increase Jenkins executors: Manage Jenkins → Configure System → # of executors
3. Enable parallel builds for multiple services

---

## 📊 Build Stages Explained

| Stage | Purpose | Time |
|-------|---------|------|
| Checkout | Clone repository | 10-30s |
| Initialize | Verify Docker, display info | 5s |
| ECR Login | Authenticate to ECR | 2-5s |
| Build [Service] | Build Docker image | 30-120s |
| Push to ECR | Push image to ECR | 10-30s |
| Cleanup | Remove old images | 5s |

**Total time for single service**: ~2-5 minutes  
**Total time for all 5 services**: ~15-20 minutes

---

## 🔐 Security Tips

1. **Change default Jenkins password immediately**
2. **Enable Jenkins security**: Manage Jenkins → Configure Global Security
3. **Limit build executor access**: Only trusted users
4. **Rotate GitHub tokens**: Every 90 days
5. **Rotate AWS keys**: Regularly
6. **Monitor webhook logs**: Check for suspicious activity
7. **Use SSL/TLS**: Configure nginx reverse proxy

---

## 📚 File Reference

| File | Purpose |
|------|---------|
| `Jenkinsfile` | Pipeline configuration (in repo root) |
| `jenkins-setup.sh` | Installation script for EC2 |
| `jenkins-setup-helper.ps1` | Windows helper for setup |
| `JENKINS_SETUP_GUIDE.md` | Detailed setup documentation |
| `GITHUB_WEBHOOK_SETUP.md` | Webhook configuration guide |
| `JENKINS_CI_REFERENCE.md` | This file |

---

## 🛠️ Useful Commands

### On EC2 Instance

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

### On Local Machine

```bash
# SSH to EC2
ssh -i durga-windows.pem ec2-user@YOUR_EC2_PUBLIC_IP

# Copy file to EC2
scp -i durga-windows.pem file.txt ec2-user@YOUR_EC2_PUBLIC_IP:/tmp/

# Copy file from EC2
scp -i durga-windows.pem ec2-user@YOUR_EC2_PUBLIC_IP:/tmp/file.txt .

# Check instance details
aws ec2 describe-instances --instance-ids i-0a4d87a45f3ad38ee --region eu-west-2
```

---

## 🎯 Next Steps

1. ✅ Install Jenkins on EC2
2. ✅ Configure credentials and plugins
3. ✅ Create pipeline job
4. ✅ Set up GitHub webhook
5. ➡️ **Test end-to-end build**
6. ➡️ Deploy to ECS
7. ➡️ Set up monitoring/alerts

---

## 📞 Getting Help

1. **Jenkins Logs**: `sudo tail -f /var/log/jenkins/jenkins.log`
2. **Docker Logs**: `sudo journalctl -u docker -f`
3. **Jenkins Docs**: https://www.jenkins.io/doc/
4. **Jenkins Plugins**: https://plugins.jenkins.io/
5. **AWS ECR Docs**: https://docs.aws.amazon.com/ecr/

---

**Last Updated**: January 16, 2026  
**Status**: Ready for CI/CD automation
