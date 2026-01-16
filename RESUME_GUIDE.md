# Jenkins CI/CD Setup - Resume Guide

**Last Updated:** January 16, 2026  
**Current Status:** AWS credentials partially configured - build still failing  
**Next Action:** Continue credential setup and trigger build

---

## 🎯 Current State Summary

### ✅ Completed
- [x] Phase 1: EC2 instance created (i-0a88cd9cc156659b8)
- [x] Phase 2: Jenkins installed on EC2
- [x] Phase 3: Jenkins web UI configured
- [x] Phase 4: GitHub webhook setup
- [x] Jenkinsfile updated (multiple fixes applied)
- [x] AWS configuration scripts created

### ⏳ In Progress
- [ ] AWS credentials properly configured for Jenkins user
- [ ] First successful build

### Critical Issue
**Problem:** AWS credential files not found at:
- `/var/lib/jenkins/.aws/credentials`
- `/var/lib/jenkins/.aws/config`

**Evidence from Build #9:**
```
⚠ Credentials file not found at /var/lib/jenkins/.aws/credentials
⚠ Config file not found at /var/lib/jenkins/.aws/config
```

---

## 🔄 Steps to Resume Tomorrow

### Step 1: Start EC2 Instance
```powershell
# Set your AWS region
$region = "eu-west-2"
$instanceId = "i-0a88cd9cc156659b8"

# Start the instance
aws ec2 start-instances --instance-ids $instanceId --region $region

# Wait for it to be running (5-10 minutes)
aws ec2 wait instance-running --instance-ids $instanceId --region $region

# Get the new public IP
aws ec2 describe-instances --instance-ids $instanceId --region $region `
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

### Step 2: Verify Services Are Running
```bash
# SSH to EC2 (replace IP with actual public IP from Step 1)
ssh -i durga-windows.pem ec2-user@YOUR_PUBLIC_IP

# Check Jenkins status
sudo systemctl status jenkins

# Check Docker status
sudo systemctl status docker

# If services are not running, start them:
sudo systemctl start jenkins
sudo systemctl start docker
```

### Step 3: Configure AWS Credentials (If Not Already Done)

The PowerShell script you ran yesterday (`configure-jenkins-aws-v2.ps1`) may need to be run again.

```powershell
# In PowerShell, from your project directory:
$key = 'YOUR_AWS_ACCESS_KEY_ID'      # From AWS Security Credentials
$secret = 'YOUR_AWS_SECRET_ACCESS_KEY' # From AWS Security Credentials
$ip = 'YOUR_NEW_PUBLIC_IP'  # Get from Step 1

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; `
.\configure-jenkins-aws-v2.ps1 -AwsAccessKey $key -AwsSecretKey $secret -EC2PublicIP $ip
```

### Step 4: Verify AWS Credentials on EC2
```bash
# SSH to EC2
ssh -i durga-windows.pem ec2-user@YOUR_PUBLIC_IP

# Check if credential files exist
ls -la /var/lib/jenkins/.aws/

# Check permissions
stat /var/lib/jenkins/.aws/credentials
stat /var/lib/jenkins/.aws/config

# Expected output: permissions should be 600 (rw-------)
```

### Step 5: Trigger a Build
```powershell
# Push a test commit to trigger webhook
cd c:\Durga Naresh\HeroVired\Assignments\durga-StreamingApp

git add .
git commit -m "test: trigger jenkins build after resume"
git push origin develop
```

### Step 6: Monitor the Build
Open in browser:
```
http://YOUR_PUBLIC_IP:8080/job/durga-streaming-app/job/develop/
```

Watch the **Initialize** stage output for:
```
✓ Credentials file found at /var/lib/jenkins/.aws/credentials
✓ Config file found at /var/lib/jenkins/.aws/config
✓ Successfully logged in to ECR
✓ Building all services...
```

---

## 📝 Important Information to Keep Handy

### EC2 Instance Details
- **Instance ID:** `i-0a88cd9cc156659b8`
- **Instance Type:** t3.medium
- **Region:** eu-west-2 (London)
- **SSH Key:** `durga-windows.pem`
- **SSH User:** `ec2-user`

### AWS Account
- **Account ID:** 975050024946
- **Region:** eu-west-2
- **Access Key ID:** Store securely (from AWS Security Credentials)
- **ECR Registry:** `975050024946.dkr.ecr.eu-west-2.amazonaws.com`

### Jenkins Details
- **Jenkins URL:** `http://PUBLIC_IP:8080` (IP changes when instance restarts)
- **Admin User:** admin (set during setup)
- **Jenkins Port:** 8080
- **Jenkins User:** jenkins
- **Jenkins Home:** /var/lib/jenkins

### GitHub Details
- **Repository:** durganaresh83/durga-StreamingApp
- **Branch:** develop
- **Credentials ID:** github-token

---

## 🔧 Files Created During Setup

Key files in your repository:
- `Jenkinsfile` - Main pipeline definition (latest fixes applied)
- `configure-jenkins-aws-v2.ps1` - AWS credential configuration script
- `setup-jenkins-aws-credentials.sh` - Bash script for AWS setup
- `jenkins-setup.sh` - Initial Jenkins installation script
- `create-jenkins-instance.ps1` - EC2 instance creation script

---

## 🐛 Troubleshooting If Build Still Fails

### If credentials file still missing:

**Option A: Manual SSH Configuration**
```bash
# SSH to EC2
ssh -i durga-windows.pem ec2-user@YOUR_PUBLIC_IP

# Manually create credentials (use YOUR actual AWS credentials)
sudo mkdir -p /var/lib/jenkins/.aws
sudo tee /var/lib/jenkins/.aws/credentials > /dev/null << EOF
[default]
aws_access_key_id = YOUR_AWS_ACCESS_KEY_ID
aws_secret_access_key = YOUR_AWS_SECRET_ACCESS_KEY
EOF

# Create config
sudo tee /var/lib/jenkins/.aws/config > /dev/null << EOF
[default]
region = eu-west-2
output = json
EOF

# Set permissions
sudo chown jenkins:jenkins /var/lib/jenkins/.aws/credentials
sudo chown jenkins:jenkins /var/lib/jenkins/.aws/config
sudo chmod 600 /var/lib/jenkins/.aws/credentials
sudo chmod 600 /var/lib/jenkins/.aws/config

# Restart Jenkins
sudo systemctl restart jenkins
```

**Option B: Re-run PowerShell Script**
```powershell
.\configure-jenkins-aws-v2.ps1 -AwsAccessKey YOUR_AWS_KEY -AwsSecretKey YOUR_AWS_SECRET -EC2PublicIP YOUR_PUBLIC_IP
```

---

## 📊 Build Progress Tracking

### Expected Build Stages:
1. ✓ Checkout - Clone from GitHub
2. ⏳ Initialize - Check environment and AWS credentials
3. ⏳ ECR Login - Login to AWS ECR (currently failing here)
4. ⏳ Build Auth Service - Docker build
5. ⏳ Build Streaming Service - Docker build
6. ⏳ Build Admin Service - Docker build
7. ⏳ Build Chat Service - Docker build
8. ⏳ Build Frontend - Docker build
9. ⏳ Push to ECR - Upload images
10. ⏳ Cleanup - Remove dangling images

---

## 💾 Stopping and Starting EC2 Instance

### To Stop (Save Costs):
```powershell
$instanceId = "i-0a88cd9cc156659b8"
$region = "eu-west-2"

aws ec2 stop-instances --instance-ids $instanceId --region $region
aws ec2 wait instance-stopped --instance-ids $instanceId --region $region
```

### To Start (Tomorrow):
```powershell
$instanceId = "i-0a88cd9cc156659b8"
$region = "eu-west-2"

aws ec2 start-instances --instance-ids $instanceId --region $region
aws ec2 wait instance-running --instance-ids $instanceId --region $region

# Get new public IP
aws ec2 describe-instances --instance-ids $instanceId --region $region `
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
```

---

## ✅ Next Session Checklist

- [ ] Stop EC2 instance (save costs)
- [ ] Save this file for reference
- [ ] Note down the Instance ID: `i-0a88cd9cc156659b8`
- [ ] Save AWS credentials in secure location
- [ ] Tomorrow: Start EC2, verify services, run credential setup, trigger build

---

## 📞 Quick Reference Commands

```powershell
# Start EC2
aws ec2 start-instances --instance-ids i-0a88cd9cc156659b8 --region eu-west-2

# Wait for startup
aws ec2 wait instance-running --instance-ids i-0a88cd9cc156659b8 --region eu-west-2

# Get public IP
aws ec2 describe-instances --instance-ids i-0a88cd9cc156659b8 --region eu-west-2 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

# SSH to instance
ssh -i durga-windows.pem ec2-user@<PUBLIC_IP>

# Configure AWS credentials (use your actual credentials)
.\configure-jenkins-aws-v2.ps1 -AwsAccessKey <YOUR_KEY> -AwsSecretKey <YOUR_SECRET> -EC2PublicIP <PUBLIC_IP>

# Trigger build
git push origin develop

# Stop EC2 (cost save)
aws ec2 stop-instances --instance-ids i-0a88cd9cc156659b8 --region eu-west-2
```

---

**Last Session End Time:** January 16, 2026, 21:55  
**Reason for Pause:** Cost optimization - stopping EC2 instance  
**Expected Resume Time:** January 17, 2026
